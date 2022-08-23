## Customize Makefile settings for phenio
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

BLMODEL = 					bl-model.ttl
BLMODEL_URL =				"https://github.com/biolink/biolink-model/blob/master/biolink-model.owl.ttl"
BLQUERY =					$(SPARQLDIR)/bl-categories.ru

## Merge Biolink Model categories
$(BLMODEL):
	wget $(BLMODEL_URL) -O $@

$(ONT).owl: $(ONT)-full.owl $(BLMODEL)
	$(ROBOT) merge --input $< --input $(BLMODEL) \
			query --update $(BLQUERY)
			unmerge -input $(BLMODEL)
	$(ROBOT) annotate --input $< --ontology-iri $(URIBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) \
		convert -o $@.tmp.owl && mv $@.tmp.owl $@

