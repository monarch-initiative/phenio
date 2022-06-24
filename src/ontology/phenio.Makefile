## Customize Makefile settings for phenio
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

# Replace the assembly of phenio-full.owl with a
# similar process including subq reconstruction

# Constants
SUBQ_QUERY_PATH =                $(SPARQLDIR)/subq_construct.sparql

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
    echo "Running update query for subq patterns..."