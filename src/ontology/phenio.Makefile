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

### Merge Biolink Model categories
$(BLMODEL):
	wget $(BLMODEL_URL) -O $@

$(ONT)-full.owl: $(TMPDIR)/$(ONT)-full-unreasoned.owl | all_robot_plugins
	$(ROBOT) merge --input $< \
		merge --input $(BLMODEL) \
		query --update $(BLQUERY) \
		unmerge --input $(BLMODEL) \
		upheno:extract-upheno-relations --root-phenotype UPHENO:0001001 --relation UPHENO:0000003 --relation UPHENO:0000001 \
		annotate --ontology-iri $(URIBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
		convert -o $@.tmp.owl && mv $@.tmp.owl $@

tmp/diff.txt: $(ONT).owl $(ONT)-old.owl
	$(ROBOT) diff --left $< --right $(word 2,$^) --format txt -o $@

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

# test artifact. A small subset of the ontology for testing purposes
# Note this does include categories.
$(ONT)-test.owl: $(ONT).owl
	echo "Creating test artifact..."
	$(ROBOT) extract --method MIREOT --input $< --branch-from-term "UPHENO:0084945" --output $@

# Compress relation-graph
$(ONT)-relation-graph.tar.gz: $(ONT)-relation-graph.tsv
	tar -czf $@ $<

# Do release to Github
public_release:
	@test $(GHVERSION)
	ls -alt $(RELEASE_ASSETS_AFTER_RELEASE)
	gh auth login
	gh release create $(GHVERSION) --title "$(VERSION)" --draft $(RELEASE_ASSETS_AFTER_RELEASE) --generate-notes

# Produce the relation graph (i.e., the fully materialized set of relations) in KGX format and json
# Note that this will also produce the main ontology file (OWL)
relation_graph: $(ONT)-relation-graph.tsv $(ONT).json
	echo "Entailed graph construction completed."

all_release: $(RELEASE_ASSETS)
	echo "All release steps completed."