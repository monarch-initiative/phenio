# Replace the assembly of phenio-full.owl with a
# similar process including subq reconstruction

# Constants
MINIMAL_PATH=					$(TMPDIR)/$(ONT)-min.owl
OT_MEMO=						50G
OWLTOOLS=						OWLTOOLS_MEMORY=$(OT_MEMO) owltools --no-logging
RG= 							relation-graph
SUBQ_QUERY_PATH=                $(SPARQLDIR)/subq_construct.sparql
SUBQ_QUERY_RESULT_PATH=         $(TMPDIR)/$(ONT)-full_subqs_queryresult.tmp.owl
UPDATE_QUERY_PATH=              $(TMPDIR)/subq_update.sparql
EXPLAIN_OUT_PATH=               $(TMPDIR)/explain_unsat.md
RELEASE_ASSETS_AFTER_RELEASE=$(foreach n,$(RELEASE_ASSETS), ./$(n))

RELEASE_ASSETS = $(ONT).owl.gz $(ONT).json $(ONT)-relation-graph.gz $(ONT)-test.owl

################################################################
#### Components ################################################
################################################################

$(COMPONENTSDIR)/go.owl: component-download-go.owl
	if [ $(COMP) = true ]; then if cmp -s $(TMPDIR)/component-download-go.owl.owl $(TMPDIR)/component-download-go.owl.tmp.owl ; then echo "Component identical."; \
      else echo "Component is different, updating." &&\
		cp $(TMPDIR)/component-download-go.owl.owl $(TMPDIR)/component-download-go.owl.tmp.owl &&\
		$(ROBOT) reason -i $(TMPDIR)/component-download-go.owl.owl relax reduce annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) -o $@; fi; fi

.PRECIOUS: $(COMPONENTSDIR)/go.owl

$(COMPONENTSDIR)/emapa.owl: component-download-emapa.owl
	if [ $(COMP) = true ]; then if cmp -s $(TMPDIR)/component-download-emapa.owl.owl $(TMPDIR)/component-download-emapa.owl.tmp.owl ; then echo "Component identical."; \
      else echo "Component is different, updating." &&\
		cp $(TMPDIR)/component-download-emapa.owl.owl $(TMPDIR)/component-download-emapa.owl.tmp.owl &&\
		$(ROBOT) query -i $(TMPDIR)/component-download-emapa.owl.owl --update ../sparql/inject-emapa-root.ru \
		relax reduce annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) -o $@; fi; fi

################################################################
#### Imports ###################################################
################################################################

ifeq ($(strip $(MIR)),true)

ONTS_WITH_NCBIGENE_DATA = $(COMPONENTSDIR)/mondo.owl

$(TMPDIR)/ncbigene_dependencies.txt: $(ONTS_WITH_NCBIGENE_DATA)
	$(ROBOT) merge $(foreach n,$(ONTS_WITH_NCBIGENE_DATA), -i $(n)) \
		query --query ../sparql/terms.sparql $(TMPDIR)/all_terms_for_ncbigene_dependencies.txt
	tr -d '\r' < $(TMPDIR)/all_terms_for_ncbigene_dependencies.txt | sed 's/.*/<&>/' | grep ncbigene | sort | uniq  > $@

../sparql/construct-ncbigene.sparql: ../sparql/construct-ncbigene.sparql.template $(TMPDIR)/ncbigene_dependencies.txt
	@sed "/{{VALUES}}/r $(TMPDIR)/ncbigene_dependencies.txt" $< | sed '/{{VALUES}}/d' > $@

mirror-ncbigene: | $(TMPDIR)
	curl -L https://github.com/monarch-initiative/ncbi-gene/releases/latest/download/ncbi_gene.nt.gz --create-dirs --retry 4 --max-time 400 | gzip -d > $(TMPDIR)/ncbigene-download.nt
	$(MAKE) ../sparql/construct-ncbigene.sparql
	arq --data=$(TMPDIR)/ncbigene-download.nt --query=../sparql/construct-ncbigene.sparql > $(TMPDIR)/mirror-ncbigene.owl

mirror-hgnc: | $(TMPDIR)
	curl -L https://data.monarchinitiative.org/monarch-kg/latest/rdf/hgnc_gene.nt.gz --create-dirs --retry 4 --max-time 400 | gzip -d > $(TMPDIR)/hgnc-download.nt && \
	arq --data=$(TMPDIR)/hgnc-download.nt --query=../sparql/construct-hgnc.sparql > $(TMPDIR)/mirror-hgnc.owl

endif

# Retrieve list of node IDs expected to be in PHENIO by downstream consumers
# Specifically Monarch
missing_phenio_nodes.tsv: | $(TMPDIR)
	curl -L https://data.monarchinitiative.org/monarch-kg-dev/latest/qc/missing_phenio_nodes.tsv --create-dirs --retry 4 --max-time 400 > $@

# Just get the CHEBI IDs
$(TMPDIR)/monarch_chebi_terms.txt: missing_phenio_nodes.tsv
	cat $^ | grep CHEBI | cut -f 1 > $@

$(IMPORTDIR)/chebi_terms_combined.txt:  $(IMPORTSEED) $(IMPORTDIR)/chebi_terms.txt $(TMPDIR)/monarch_chebi_terms.txt
	cat $^ | grep -v ^# | sort | uniq > $@

# Just get the PR IDs
$(TMPDIR)/monarch_pr_terms.txt: missing_phenio_nodes.tsv
	cat $^ | grep PR | cut -f 1 > $@

$(IMPORTDIR)/pr_terms_combined.txt:  $(IMPORTSEED) $(IMPORTDIR)/pr_terms.txt $(TMPDIR)/monarch_pr_terms.txt
	cat $^ | grep -v ^# | sort | uniq > $@

################################################################
#### Release files #############################################
################################################################

# Base file assembly
$(TMPDIR)/$(ONT)-full-unreasoned.owl: $(SRC) $(OTHER_SRC) $(IMPORT_FILES)
	$(ROBOT) merge --input $< $(patsubst %, -i %, $(OTHER_SRC)) $(patsubst %, -i %, $(IMPORT_FILES)) \
		--annotate-derived-from true --output $@

# Run a robot explain to check for unsatisfiable classes before next step
$(EXPLAIN_OUT_PATH): $(TMPDIR)/$(ONT)-full-unreasoned.owl
	$(ROBOT) explain -i $< -M unsatisfiability --unsatisfiable random:10 --explanation $@

# removed this --update $(SPARQLDIR)/bl-categories.ru as we decided it was no longer needed here.
phenio-full.owl: $(TMPDIR)/$(ONT)-full-unreasoned.owl $(MAPPINGDIR)/cl.sssom.tsv $(MAPPINGDIR)/uberon.sssom.tsv $(MAPPINGDIR)/upheno-oba.sssom.tsv | all_robot_plugins
	$(ROBOT) merge --input $< \
		remove --select "<http://birdgenenames.org/cgnc/*>" \
		remove --select "<http://flybase.org/reports/*>" \
		remove --select "<http://purl.obolibrary.org/obo/CARO_*>" \
		remove --select "<http://purl.obolibrary.org/obo/ECTO_*>" \
		remove --select "<http://purl.obolibrary.org/obo/ENVO_*>" \
		remove --select "<http://purl.obolibrary.org/obo/FAO_*>" \
		remove --select "<http://purl.obolibrary.org/obo/GOCHE_*>" \
		remove --select "<http://purl.obolibrary.org/obo/MFOMD_*>" \
		remove --select "<http://purl.obolibrary.org/obo/MF_*>" \
		remove --select "<http://purl.obolibrary.org/obo/MOD_*>" \
		remove --select "<http://purl.obolibrary.org/obo/NCBITaxon_Union_*>" \
		remove --select "<http://purl.obolibrary.org/obo/NCIT_*>" \
		remove --select "<http://purl.obolibrary.org/obo/OBI_*>" \
		remove --select "<http://purl.obolibrary.org/obo/OGMS_*>" \
		remove --select "<http://purl.obolibrary.org/obo/PCO_*>" \
		remove --select "<http://purl.obolibrary.org/obo/FOODON_*>" \
		remove --select "<http://purl.obolibrary.org/obo/PO_*>" \
		remove --select "<http://purl.obolibrary.org/obo/BTO_*>" \
		remove --select "<http://purl.obolibrary.org/obo/RnorDv_*>" \
		remove --select "<http://purl.obolibrary.org/obo/COB_*>" \
		remove --select "<http://purl.obolibrary.org/obo/emapa#*>" \
		remove --select "<http://www.ebi.ac.uk/efo/EFO_*>" \
		remove --select "<http://purl.obolibrary.org/obo/TS_*>" \
		remove --select "<http://www.informatics.jax.org/marker/MGI:*>" \
		remove --select "<https://swisslipids.org/rdf/SLM_*>" \
		remove --select "<http://purl.obolibrary.org/obo/OPL_*>" \
		remove --select "<https://bioregistry.io/lipidmaps*>" \
		remove --select "<http://org.semanticweb.owlapi/error*>" \
		remove --term owl:Thing --term owl:Nothing \
		rename --mappings config/property-map.tsv --allow-missing-entities true --allow-duplicates true \
		sssom:inject --sssom $(MAPPINGDIR)/uberon.sssom.tsv \
		             --sssom $(MAPPINGDIR)/cl.sssom.tsv \
		              --ruleset config/mappings-to-uberon-bridge.rules \
		sssom:inject --sssom $(MAPPINGDIR)/upheno-oba.sssom.tsv \
		              --ruleset config/mappings-to-upheno-oba.rules \
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
$(ONT)-relation-graph.gz: $(ONT)-relation-graph.tsv
	gzip -c $< > $@

$(ONT).owl.gz: $(ONT).owl
	gzip -c $< > $@

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