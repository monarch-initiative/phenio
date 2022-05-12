## Customize Makefile settings for phenio
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

# An extra endpoint just to prepare empty sources
IMPORTS =  nbo fao oba stato bfo hsapdv mpath ncbitaxon-taxslim caro uberon uberon-bridge-to-zfa uberon-bridge-to-ma uberon-bridge-to-wbbt uberon-bridge-to-fbbt uberon-bridge-to-fma uberon-bridge-to-nifstd cl-bridge-to-ma cl-bridge-to->

IMPORT_UNMERGED_FILES = $(foreach n,$(IMPORTS), imports/$(n)_import.owl)

prepare_repo:
	touch $(IMPORT_UNMERGED_FILES) $(OTHER_SRC)
