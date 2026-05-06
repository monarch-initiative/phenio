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

RELEASE_ASSETS = $(ONT).owl.gz $(ONT).json $(ONT)-relation-graph.gz $(ONT)-test.owl $(ONT)-sspo-equivalent.owl.gz $(ONT)-upstream-versions.tsv
RELEASE_ASSETS_AFTER_RELEASE=$(foreach n,$(RELEASE_ASSETS), ./$(n))

# Add the upstream-versions component to the OTHER_SRC list defined in the
# auto-generated Makefile so it gets merged into phenio.owl alongside the
# other components. The recipe bodies (which use `$(OTHER_SRC)` lazily)
# pick this up; the rule prereq lists, however, were resolved at parse
# time before this file was included, so they don't see the `+=`.
# Declare the dep explicitly on each rule that consumes $(OTHER_SRC) so
# make builds upstream-versions.owl before those merges run.
OTHER_SRC += $(COMPONENTSDIR)/upstream-versions.owl

$(SRCMERGED) $(ONT)-base.owl $(ONT)-full.owl all_components: $(COMPONENTSDIR)/upstream-versions.owl

################################################################
#### Components ################################################
################################################################

ifeq ($(MIR),true)

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

endif # MIR=true

################################################################
#### Upstream version manifest #################################
################################################################

# Capture versionIRI / versionInfo of each upstream by querying the
# already-downloaded $(TMPDIR)/mirror-*.owl files. Produces:
#   - $(ONT)-upstream-versions.tsv: human-readable manifest, shipped as
#     a release asset.
#   - $(COMPONENTSDIR)/upstream-versions.owl: a tiny RDF/XML component
#     merged into phenio.owl, asserting one dcterms:source per upstream
#     versionIRI on the phenio ontology IRI.
#
# The recipe globs $(TMPDIR)/mirror-*.owl at recipe-execution time. To make
# that safe under parallel make (-j N) — where the TSV target would
# otherwise run as a sibling of the mirror-producing targets and finish
# before any mirror exists — we declare order-only prerequisites on the
# imports and non-self components, both of which transitively pull mirror
# downloads. Order-only (`|`) prevents these prereqs from re-triggering the
# .PHONY recipe; they only enforce ordering. We filter out
# upstream-versions.owl from OTHER_SRC to avoid a self-cycle (it depends on
# this very TSV).

UPSTREAM_VERSIONS_SPARQL = $(SPARQLDIR)/get-upstream-version.sparql
UPSTREAM_VERSIONS_DEPS = $(IMPORT_FILES) $(filter-out $(COMPONENTSDIR)/upstream-versions.owl,$(OTHER_SRC))

.PHONY: upstream_versions
upstream_versions: $(ONT)-upstream-versions.tsv $(COMPONENTSDIR)/upstream-versions.owl

.PHONY: $(ONT)-upstream-versions.tsv
$(ONT)-upstream-versions.tsv: $(UPSTREAM_VERSIONS_SPARQL) | $(UPSTREAM_VERSIONS_DEPS) $(TMPDIR)
	@printf "source\tontologyIRI\tversionIRI\tversionInfo\n" > $@
	@for f in $(TMPDIR)/mirror-*.owl; do \
	  [ -s "$$f" ] || continue; \
	  src=$$(basename "$$f" .owl); src=$${src#mirror-}; \
	  out=$(TMPDIR)/upstream-version-$$src.tsv; \
	  $(ROBOT) query -i "$$f" -f tsv --query $< "$$out" >/dev/null 2>&1 || continue; \
	  tail -n +2 "$$out" \
	    | awk -v src="$$src" 'BEGIN{FS=OFS="\t"} \
	        { for (i=1;i<=NF;i++) { sub(/^</,"",$$i); sub(/>$$/,"",$$i); \
	                                sub(/^"/,"",$$i); sub(/"$$/,"",$$i) } } \
	        $$1!="" {print src,$$1,$$2,$$3}' >> $@; \
	done
	@rows=$$(($$(wc -l < $@) - 1)); \
	if [ $$rows -eq 0 ]; then \
	  echo "ERROR: $@ produced zero data rows. Mirror files in $(TMPDIR) may not be ready." >&2; \
	  ls -la $(TMPDIR)/mirror-*.owl 2>&1 >&2 || true; \
	  exit 1; \
	fi; \
	echo "$@: wrote $$rows upstream version row(s)"

$(COMPONENTSDIR)/upstream-versions.owl: $(ONT)-upstream-versions.tsv | $(COMPONENTSDIR)
	@awk 'BEGIN { \
	    FS = "\t"; \
	    print "<?xml version=\"1.0\"?>"; \
	    print "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\""; \
	    print "         xmlns:owl=\"http://www.w3.org/2002/07/owl#\""; \
	    print "         xmlns:rdfs=\"http://www.w3.org/2000/01/rdf-schema#\""; \
	    print "         xmlns:dcterms=\"http://purl.org/dc/terms/\">"; \
	    print "    <owl:Ontology rdf:about=\"http://purl.obolibrary.org/obo/phenio.owl\">"; \
	    print "        <rdfs:comment>Upstream ontology versions used in this PHENIO release. Each dcterms:source links to the versionIRI of the upstream artifact consumed at build time.</rdfs:comment>"; \
	  } \
	  NR > 1 { \
	    target = ($$3 != "") ? $$3 : $$2; \
	    if (target != "") printf "        <dcterms:source rdf:resource=\"%s\"/>\n", target; \
	  } \
	  END { \
	    print "    </owl:Ontology>"; \
	    print "</rdf:RDF>"; \
	  }' $< > $@

.PRECIOUS: $(COMPONENTSDIR)/upstream-versions.owl

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
	curl -L https://github.com/monarch-initiative/hgnc-ingest/releases/latest/download/hgnc_gene.nt.gz --create-dirs --retry 4 --max-time 400 | gzip -d > $(TMPDIR)/hgnc-download.nt && \
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
		remove --select "<hhttps://purl.brain-bican.org/ontology/mbao/MBA_*>" \
		remove --select "<http://purl.obolibrary.org/obo/CLM_*>" \
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

###############################
## Custom release variants ####
###############################

tmp/phenio-sspo-equivalent.owl: phenio.owl
	$(ROBOT) query --input phenio.owl \
		 --query ../sparql/phenio-sspo-equivalent.sparql $@

phenio-sspo-equivalent.owl: tmp/phenio-sspo-equivalent.owl phenio.owl
	$(ROBOT) merge -i phenio.owl -i tmp/phenio-sspo-equivalent.owl \
		remove --axioms "disjoint" \
		reason \
		relax \
		reduce \
		annotate --ontology-iri $(URIBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
		convert -o $@

# The below was a failed attempt to  create a phenio version without subclass axioms between SSPO phenotypes
#tmp/phenio-sspo-subclass.owl: phenio.owl
#	$(ROBOT) query --input phenio.owl \
#		 --query ../sparql/phenio-sspo-subclass.sparql $@
#
#phenio-sspo-subclass.owl: tmp/phenio-sspo-subclass.owl phenio.owl
#	$(ROBOT) merge -i phenio.owl -i tmp/phenio-sspo-subclass.owl \
#		remove --axioms "disjoint" \
#		remove --term UPHENO:0001001 --select "descendants" --select "HP:* MP:* ZP:*" --drop-axiom-annotations all \
#		remove --term UPHENO:0001001 --select "descendants" --select "HP:* MP:* ZP:*" --axioms "SubClassOf" --trim false --signature true \
#		relax \
#		reduce \
#		annotate --ontology-iri $(URIBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
#		convert -o $@

full_test_build_equivalent:
	$(MAKE) phenio-sspo-equivalent.owl
	$(MAKE) diff-phenio-sspo-equivalent

diff-%: phenio.owl
	$(ROBOT) diff --left phenio.owl --right $*.owl -o tmp/diff_$*.txt
	$(ROBOT) merge -i $*.owl unmerge -i phenio.owl -o tmp/unmerged_$*.owl

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

phenio-sspo-equivalent.owl.gz: phenio-sspo-equivalent.owl
	gzip -c $< > $@

# Do release to Github
public_release:
	@test $(GHVERSION)
	ls -alt $(RELEASE_ASSETS_AFTER_RELEASE)
	gh auth login
	gh release create $(GHVERSION) --title "$(VERSION)" --latest $(RELEASE_ASSETS_AFTER_RELEASE) --generate-notes

# Do release to Github, but assume the gh auth is already done.
# Used by Jenkins after `all_release`; relies on $GH_TOKEN being exported
# (Jenkinsfile aliases its GH_RELEASE_TOKEN credential into GH_TOKEN).
public_release_auto:
	ls -alt $(RELEASE_ASSETS_AFTER_RELEASE)
	gh release create $(GHVERSION) --title "$(VERSION)" --latest $(RELEASE_ASSETS_AFTER_RELEASE) --generate-notes

# Produce the relation graph (i.e., the fully materialized set of relations) in KGX format and json
# Note that this will also produce the main ontology file (OWL)
relation_graph: $(ONT)-relation-graph.tsv $(ONT).json
	echo "Entailed graph construction completed."

all_release: $(RELEASE_ASSETS)
	echo "All release steps completed."
