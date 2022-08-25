## Customize Makefile settings for phenio
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

# Replace the assembly of phenio-full.owl with a
# similar process including subq reconstruction

# Constants
RG= 							relation-graph
SUBQ_QUERY_PATH=                $(SPARQLDIR)/subq_construct.sparql
SUBQ_QUERY_RESULT_PATH=         $(TMPDIR)/$(ONT)-full_subqs_queryresult.tmp.owl
UPDATE_QUERY_PATH=              $(TMPDIR)/subq_update.sparql
MINIMAL_PATH=					$(TMPDIR)/$(ONT)-min.owl


# Base file assembly
$(TMPDIR)/$(ONT)-full-unreasoned.owl: $(SRC) $(OTHER_SRC)
	$(ROBOT) merge --input $< $(patsubst %, -i %, $(OTHER_SRC)) $(patsubst %, -i %, $(IMPORT_FILES)) \
		--output $@
	# Run a robot explain to check for unsatisfiable classes before next step
	$(ROBOT) explain -i $@ -M unsatisfiability --unsatisfiable random:10 --explanation tmp/explain_unsat.md 

$(TMPDIR)/$(ONT)-full.owl: $(TMPDIR)/$(ONT)-full-unreasoned.owl
	# $(ROBOT) reason --input $< \
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

### Replace profile-based validation functions to ignore

$(REPORTDIR)/validate_profile_owl2dl_%.txt: % | $(REPORTDIR) $(TMPDIR)
	touch $(TMPDIR)/validate.ofn
	touch $@
.PRECIOUS: $(REPORTDIR)/validate_profile_owl2dl_%.txt

validate_profile_%: $(REPORTDIR)/validate_profile_owl2dl_%.txt
	echo "$* profile validation skipped."

### Get full entailment with relation-graph

.PHONY: make_relation_graph
make_relation_graph: $(ONT).owl
	$(ROBOT) remove -i $< --axioms "equivalent disjoint annotation" -o $(MINIMAL_PATH)
	$(RG) --disable-owl-nothing true \
			--ontology-file $(MINIMAL_PATH)\
			--output-file $(ONT)-relation-graph.ttl \
			--equivalence-as-subclass true \
			--output-subclasses true \
			--reflexive-subclasses true \
			--verbose true \
			--mode rdf