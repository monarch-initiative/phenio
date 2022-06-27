## Customize Makefile settings for phenio
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

# Replace the assembly of phenio-full.owl with a
# similar process including subq reconstruction

# Constants
SUBQ_QUERY_PATH=                $(SPARQLDIR)/subq_construct.sparql
SUBQ_QUERY_RESULT_PATH=         $(TMPDIR)/subqs_queryresult.tmp.owl
UPDATE_QUERY_PATH=              $(TMPDIR)/subq_update.sparql

# Full file assembly
$(ONT)-full.owl: $(SRC) $(OTHER_SRC) $(IMPORT_FILES)
	$(ROBOT) merge --input $< \
		reason --reasoner ELK --equivalent-classes-allowed asserted-only --exclude-tautologies structural \
		relax \
		reduce -r ELK \
		$(SHARED_ROBOT_COMMANDS) annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@

	echo "Finding subq patterns based on $(SUBQ_QUERY_PATH)..."
	$(ROBOT) query --input $@ --format 'owl' --query $(SUBQ_QUERY_PATH) $(SUBQ_QUERY_RESULT_PATH)
	echo "Creating update query..."
	awk -v RS= 'NR==1' $(SUBQ_QUERY_PATH) > $(UPDATE_QUERY_PATH)
	echo -e "\nINSERT DATA\n{" >> $(UPDATE_QUERY_PATH)
	tail -n +3 $(SUBQ_QUERY_RESULT_PATH) >> $(UPDATE_QUERY_PATH)
    grep subClassOf $(UPDATE_QUERY_PATH) | wc -l

	echo "Running update query for subq patterns..."
	$(ROBOT) query --input $@ --format 'owl' --update $(UPDATE_QUERY_PATH) --temporary-file 'true' --output $(TMPDIR)/$@.tmp.owl && mv $(TMPDIR)/$@.tmp.owl $@
	echo "Completed update with subq patterns."