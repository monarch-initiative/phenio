## Customize Makefile settings for phenio
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

# Replace the assembly of phenio-full.owl with a
# similar process including subq reconstruction

# Constants
SUBQ_QUERY_PATH=                $(SPARQLDIR)/subq_construct.sparql
UPDATE_QUERY_PATH=              ./subq_update.sparql

# Full file assembly
$(ONT)-full.owl: $(SRC) $(OTHER_SRC) $(IMPORT_FILES)
	$(ROBOT) merge --input $< \
		reason --reasoner ELK --equivalent-classes-allowed asserted-only --exclude-tautologies structural \
		relax \
		reduce -r ELK \
		$(SHARED_ROBOT_COMMANDS) annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@

	echo "Finding subq patterns based on $(SUBQ_QUERY_PATH)..."
	$(ROBOT) query --input $@ --format 'owl' --query $(SUBQ_QUERY_PATH) $@_subqs_queryresult.tmp.owl
	echo "Creating update query..."
	awk -v RS= 'NR==1' $(SUBQ_QUERY_PATH) > $(UPDATE_QUERY_PATH)
	echo -e "INSERT DATA\n{\n" >> $(UPDATE_QUERY_PATH)
	tail -n +3 $@_subqs_queryresult.tmp.owl >> $(UPDATE_QUERY_PATH)

	echo "Running update query for subq patterns..."
	$(ROBOT) query --input $@ --format 'owl' --update $(UPDATE_QUERY_PATH) --temporary-file 'true' --output $@.tmp.owl && mv $@.tmp.owl $@
	echo "Completed update with subq patterns."