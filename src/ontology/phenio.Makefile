# Replace the assembly of phenio-full.owl with a
# similar process including subq reconstruction

# Constants
BLMODEL = 					bl-model.ttl
BLMODEL_URL =				"https://github.com/biolink/biolink-model/blob/master/biolink-model.owl.ttl"
BLQUERY =					$(SPARQLDIR)/bl-categories.ru
MINIMAL_PATH=					$(TMPDIR)/$(ONT)-min.owl
OT_MEMO=						50G
OWLTOOLS=						OWLTOOLS_MEMORY=$(OT_MEMO) owltools --no-logging
RG= 							relation-graph
SUBQ_QUERY_PATH=                $(SPARQLDIR)/subq_construct.sparql
SUBQ_QUERY_RESULT_PATH=         $(TMPDIR)/$(ONT)-full_subqs_queryresult.tmp.owl
UPDATE_QUERY_PATH=              $(TMPDIR)/subq_update.sparql
EXPLAIN_OUT_PATH=               $(TMPDIR)/explain_unsat.md

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
	$(ROBOT) query --input $< --format 'owl' --query $(SUBQ_QUERY_PATH) $@

$(UPDATE_QUERY_PATH): $(SUBQ_QUERY_RESULT_PATH)
	#echo "Creating update query..."
	awk -v RS= 'NR==1' $(SUBQ_QUERY_PATH) > $@
	printf '\nINSERT DATA\n{' >> $@
	tail -n +3 $< >> $@
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
			query --update $(BLQUERY)
			unmerge -input $(BLMODEL)
	$(ROBOT) annotate --input $< --ontology-iri $(URIBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
		convert -o $@.tmp.owl && mv $@.tmp.owl $@

### Get full entailment with relation-graph
$(MINIMAL_PATH): $(ONT).owl
	$(ROBOT) remove -i $< --axioms "equivalent disjoint annotation" --select "domains ranges" -o $@

$(ONT)-relation-graph.ttl: $(MINIMAL_PATH)
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
			--reflexive-subclasses true \
			--verbose true \
			--mode rdf \
			--property "rdfs:subClassOf"

relation_graph: $(ONT)-relation-graph.ttl
	echo "Entailed graph construction completed."