## Customize Makefile settings for phenio
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

# Replace the assembly of phenio-full.owl with a
# similar process including subq reconstruction

# Constants
SUBQ_QUERY_PATH=                $(SPARQLDIR)/subq_construct.sparql
SUBQ_QUERY_RESULT_PATH=         $(TMPDIR)/$(ONT)-full_subqs_queryresult.tmp.owl
UPDATE_QUERY_PATH=              $(TMPDIR)/subq_update.sparql

# Base file assembly
$(TMPDIR)/$(ONT)-base.owl: $(SRC) $(OTHER_SRC)
	$(ROBOT) remove --input $< --select imports --trim false \
		merge $(patsubst %, -i %, $(OTHER_SRC)) \
		 $(SHARED_ROBOT_COMMANDS) annotate --link-annotation http://purl.org/dc/elements/1.1/type http://purl.obolibrary.org/obo/IAO_8000001 \
		--ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
		--output $@.tmp.owl && mv $@.tmp.owl $@

$(SUBQ_QUERY_RESULT_PATH): $(TMPDIR)/$(ONT)-full.owl
	#echo "Finding subq patterns based on $(SUBQ_QUERY_PATH)..."
	$(ROBOT) query --input $< --format 'owl' --query $(SUBQ_QUERY_PATH) $@

$(UPDATE_QUERY_PATH): $(SUBQ_QUERY_RESULT_PATH)
	#echo "Creating update query..."
	awk -v RS= 'NR==1' $(SUBQ_QUERY_PATH) > $@
	echo -e "\nINSERT DATA\n{" >> $@
	tail -n +3 $< >> $@
	grep subClassOf $@ | wc -l

$(ONT).owl: $(TMPDIR)/$(ONT)-base.owl $(UPDATE_QUERY_PATH)
	#echo "Running update query for subq patterns..."
	$(ROBOT) query --input $< --format 'owl' --update $(UPDATE_QUERY_PATH) --temporary-file 'true' annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION)
	#echo "Completed update with subq patterns."
