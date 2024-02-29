# Replace the assembly of phenio-full.owl with a
# similar process including subq reconstruction

# Constants
BLMODEL = 					bl-model.ttl
BLMODEL_URL =				"https://w3id.org/biolink/biolink-model.owl.ttl"
BLQUERY =					$(SPARQLDIR)/bl-categories.ru
MINIMAL_PATH=					$(TMPDIR)/$(ONT)-min.owl
OT_MEMO=						50G
OWLTOOLS=						OWLTOOLS_MEMORY=$(OT_MEMO) owltools --no-logging
RG= 							relation-graph
SUBQ_QUERY_PATH=                $(SPARQLDIR)/subq_construct.sparql
SUBQ_QUERY_RESULT_PATH=         $(TMPDIR)/$(ONT)-full_subqs_queryresult.tmp.owl
UPDATE_QUERY_PATH=              $(TMPDIR)/subq_update.sparql
EXPLAIN_OUT_PATH=               $(TMPDIR)/explain_unsat.md
RELEASE_ASSETS_AFTER_RELEASE=$(foreach n,$(RELEASE_ASSETS), ./$(n))

RELEASE_ASSETS = $(ONT).owl $(ONT).json $(ONT)-relation-graph.tar.gz $(ONT)-test.owl

# Base file assembly
$(TMPDIR)/$(ONT)-full-unreasoned.owl: $(SRC) $(OTHER_SRC)
	$(ROBOT) merge --input $< $(patsubst %, -i %, $(OTHER_SRC)) $(patsubst %, -i %, $(IMPORT_FILES)) \
		--output $@

# Run a robot explain to check for unsatisfiable classes before next step
$(EXPLAIN_OUT_PATH): $(TMPDIR)/$(ONT)-full-unreasoned.owl
	$(ROBOT) explain -i $< -M unsatisfiability --unsatisfiable random:10 --explanation $@

$(TMPDIR)/$(ONT)-full.owl: $(TMPDIR)/$(ONT)-full-unreasoned.owl
	#$(ROBOT) reason --input $< \
	# 	--reasoner ELK --equivalent-classes-allowed all --exclude-tautologies structural \
	# 	relax \
	# 	reduce -r ELK \
	# 	$(SHARED_ROBOT_COMMANDS) annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@
	$(ROBOT) relax --input $< \
 	    $(SHARED_ROBOT_COMMANDS) annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@

$(SUBQ_QUERY_RESULT_PATH): $(TMPDIR)/$(ONT)-full.owl
	#echo "Finding subq patterns based on $(SUBQ_QUERY_PATH)..."
	$(ROBOT) query --input $< --tdb true --format 'owl' --query $(SUBQ_QUERY_PATH) $@

$(UPDATE_QUERY_PATH): $(SUBQ_QUERY_RESULT_PATH)
	#echo "Creating update query..."
	awk -v RS= 'NR==1' $(SUBQ_QUERY_PATH) > $@
	tail -n +3 $<| sed -e '/./!Q' -e 's/@prefix/PREFIX/g' -e 's/.$$//' >> $@
	printf '\nINSERT DATA\n{' >> $@
	sed -n '/rdfs:subClassOf/,$$p' $< >> $@
	printf '\n}' >> $@
	grep subClassOf $@ | wc -l

$(ONT)-full.owl: $(TMPDIR)/$(ONT)-full.owl $(UPDATE_QUERY_PATH)
	#echo "Running update query for subq patterns..."
	$(ROBOT) query --input $< --format 'owl' --update $(UPDATE_QUERY_PATH) --temporary-file 'true' annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@
	#echo "Completed update with subq patterns."
  
### Merge Biolink Model categories
$(BLMODEL):
	wget $(BLMODEL_URL) -O $@

$(ONT).owl: $(ONT)-full.owl $(BLMODEL)
	$(ROBOT) merge --input $< --input $(BLMODEL) \
			 query --update $(BLQUERY) \
			 unmerge --input $(BLMODEL) \
			 annotate --ontology-iri $(URIBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
			 convert -o $@.tmp.owl && mv $@.tmp.owl $@

### Get full entailment with relation-graph
### First, make a minimal version
$(MINIMAL_PATH): $(ONT).owl
	$(ROBOT) remove -i $< \
		--axioms "equivalent disjoint annotation" \
		filter --exclude-terms exclude-terms.txt \
		-o $@

$(ONT)-relation-graph.tsv: $(MINIMAL_PATH)
###	$(OWLTOOLS) $< --merge-imports-closure \
###					--remove-axioms -t DisjointClasses \
###					--remove-axioms -t ObjectPropertyDomain \
###					--remove-axioms -t ObjectPropertyRange -t DisjointUnion \
###					--remove-disjoints \
###					--remove-equivalent-to-nothing-axioms \
###					-o $(MINIMAL_PATH)
	$(RG) --disable-owl-nothing true \
			--ontology-file $< \
			--output-file $@ \
			--equivalence-as-subclass true \
			--output-subclasses true \
			--output-individuals true \
			--reflexive-subclasses true \
			--mode TSV \
			--obo-prefixes true \
			--verbose true

# base-plus. No externally imported axioms, but reasoning is performed.
$(ONT)-base-plus.owl: $(EDIT_PREPROCESSED) $(OTHER_SRC) $(IMPORT_FILES)
	$(ROBOT_RELEASE_IMPORT_MODE) \
	reason --reasoner ELK --equivalent-classes-allowed all --exclude-tautologies structural \
	relax \
	reduce -r ELK \
	remove --base-iri $(URIBASE)/PHENIO --axioms external --preserve-structure false --trim false \
	$(SHARED_ROBOT_COMMANDS) \
	annotate --link-annotation http://purl.org/dc/elements/1.1/type http://purl.obolibrary.org/obo/IAO_8000001 \
		--ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
		--output $@.tmp.owl && mv $@.tmp.owl $@

# test artifact. A small subset of the ontology for testing purposes
# Note this does include categories.
$(ONT)-test.owl: $(ONT).owl
	echo "Creating test artifact..."
	$(ROBOT) extract --method BOT --input $< --term-file test_module.txt --output $@

# Do release to Github
# Compress relation-graph first
public_release:
	@test $(GHVERSION)
	tar -czf $(ONT)-relation-graph.tar.gz $(ONT)-relation-graph.tsv
	ls -alt $(RELEASE_ASSETS_AFTER_RELEASE)
	gh auth login
	gh release create $(GHVERSION) --title "$(VERSION)" --draft $(RELEASE_ASSETS_AFTER_RELEASE) --generate-notes

# Produce the relation graph (i.e., the fully materialized set of relations) in KGX format and json
# Note that this will also produce the main ontology file (OWL)
relation_graph: $(ONT)-relation-graph.tsv $(ONT).json
	echo "Entailed graph construction completed."

all_release: $(RELEASE_ASSETS)
	echo "All release steps completed."