# Composition of PHENIO

PHENIO (Phenomics Integrated Ontology) is an application ontology that integrates multiple ontologies and data sources to enable cross-species phenotype comparisons. This page documents all ontologies, components, and mapping sets included in PHENIO.

For details on the difference between PHENIO and uPHENO, see [PHENIO vs uPHENO](phenio_vs_upheno.md).

## Import Modules

Import modules are ontologies included via the OBO standard import mechanism. PHENIO uses base-merging to include only the terms directly asserted in each source ontology.

### Upper-Level and Foundational Ontologies

* **BFO**: Basic Formal Ontology (https://basic-formal-ontology.org/) - an upper-level ontology that provides a set of categories for organizing knowledge and facilitating interoperability between ontologies.

* **RO**: Relations Ontology (http://www.obofoundry.org/ontology/ro.html) - an ontology that defines relationships between entities in other ontologies, providing a foundation for relating information across different domains.

* **PATO**: Phenotypic Quality Ontology (http://www.obofoundry.org/ontology/pato.html) - an ontology that provides a standardized vocabulary to describe phenotypic qualities, such as height, weight, and shape.

* **ECO**: Evidence and Conclusion Ontology (https://evidenceontology.org/) - an ontology that categorizes and organizes different types of evidence used in scientific research and draws conclusions based on that evidence.

### Chemical and Molecular Ontologies

* **CHEBI (Slim)**: Chemical Entities of Biological Interest (https://www.ebi.ac.uk/chebi/) - a dictionary of molecular entities; PHENIO uses a simplified subset (available from https://github.com/obophenotype/chebi_obo_slim).

* **PR (Slim)**: Protein Ontology (https://obofoundry.org/ontology/pr.html) - an ontology of protein types covering organisms of biomedical interest; PHENIO uses a simplified subset (available from https://github.com/obophenotype/pro_obo_slim).

### Gene and Sequence Identifiers

* **NCBI Gene**: NCBI Gene (https://www.ncbi.nlm.nih.gov/gene) - NCBI Gene identifiers for cross-referencing genes across species.

* **HGNC**: HUGO Gene Nomenclature Committee (https://www.genenames.org/) - standardized gene naming and identifiers for human genes.

* **SO**: Sequence Ontology (https://obofoundry.org/ontology/so.html) - an ontology describing biological sequence features, attributes, and relationships.

* **Monochrom**: Chromosome Ontology (https://github.com/monarch-initiative/monochrom) - an ontology of chromosomes for representing karyotype information.

### Spatial Ontology

* **BSPO**: Biological Spatial Ontology (https://obofoundry.org/ontology/bspo.html) - an ontology for representing spatial and positional relationships of anatomical entities.

### Developmental Stage Ontologies

* **WBls**: WormBase Life Stages (https://obofoundry.org/ontology/wbls.html) - an ontology of life stages for *C. elegans*.

* **ZFS**: Zebrafish Stages (https://obofoundry.org/ontology/zfs.html) - an ontology of zebrafish developmental stages.

* **FBdv**: FlyBase Development Ontology (https://obofoundry.org/ontology/fbdv.html) - an ontology of *Drosophila melanogaster* developmental stages.

### Pathology and Behavior Ontologies

* **MPATH**: Mouse Pathology Ontology (https://obofoundry.org/ontology/mpath.html) - an ontology that standardizes and classifies phenotypic abnormalities observed in various mutant mouse strains.

* **NBO**: Neuro Behavior Ontology (https://obofoundry.org/ontology/nbo.html) - an ontology that defines behavioral and neurological phenotypes to support research in neuroscience and behavior genetics.

### Taxonomy

* **NCBITaxon (Slim)**: NCBI Taxonomy (https://www.ncbi.nlm.nih.gov/taxonomy) - a taxonomy database that classifies and names living organisms; PHENIO uses a simplified subset (available from http://purl.obolibrary.org/obo/ncbitaxon/subsets/taxslim.owl).

## Components

Components are ontologies merged into PHENIO as full modules using their base release, rather than being subset by PHENIO-specific terms.

### Phenotype Ontologies

* **uPHENO**: Unified Phenotype Ontology (https://github.com/obophenotype/upheno) - a framework ontology that links phenotypic abnormalities to the anatomical entities that are affected, enabling cross-species genotype-phenotype comparisons.

* **HP**: Human Phenotype Ontology (https://hpo.jax.org/) - a standardized vocabulary of phenotypic abnormalities observed in human disease.

* **MP**: Mammalian Phenotype Ontology (https://obofoundry.org/ontology/mp.html) - an ontology of phenotypic abnormalities observed in mammals, primarily mouse.

* **ZP**: Zebrafish Phenotype Ontology (https://obofoundry.org/ontology/zp.html) - an ontology of phenotypes observed in zebrafish (*Danio rerio*).

* **XPO**: Xenopus Phenotype Ontology (https://obofoundry.org/ontology/xpo.html) - an ontology of phenotypes observed in *Xenopus* (frogs).

* **DPO**: Drosophila Phenotype Ontology (https://obofoundry.org/ontology/dpo.html) - an ontology of phenotypes observed in *Drosophila melanogaster*.

* **FYPO**: Fission Yeast Phenotype Ontology (https://obofoundry.org/ontology/fypo.html) - an ontology of phenotypes observed in fission yeast (*Schizosaccharomyces pombe*).

* **WBPhenotype**: WormBase Phenotype Ontology (https://obofoundry.org/ontology/wbphenotype.html) - an ontology of phenotypes observed in *Caenorhabditis elegans*.

* **DDPHENO**: Dictyostelium Phenotype Ontology (https://obofoundry.org/ontology/ddpheno.html) - an ontology of phenotypes observed in *Dictyostelium discoideum* (slime mold).

* **OBA**: Ontology of Biological Attributes (https://obofoundry.org/ontology/oba.html) - an ontology that describes biological attributes such as size, shape, color, and behavior across different species.

### Disease and Medical Action Ontologies

* **MONDO**: Monarch Disease Ontology (https://mondo.monarchinitiative.org/) - an ontology that integrates disease-related information from various sources to facilitate the understanding of human diseases.

* **MAXO**: Medical Action Ontology (https://obofoundry.org/ontology/maxo.html) - an ontology of medical procedures, interventions, and therapies used in the treatment of diseases.

### Gene Ontology

* **GO**: Gene Ontology (http://geneontology.org/) - a widely-used ontology that categorizes gene products' functions in various biological processes, cellular components, and molecular functions.

### Anatomy Ontologies

* **UBERON**: Integrated Cross-Species Anatomy Ontology (https://obofoundry.org/ontology/uberon.html) - an ontology that integrates anatomical information from different species, facilitating cross-species comparisons.

* **CL**: Cell Ontology (https://obofoundry.org/ontology/cl.html) - an ontology representing cell types across species.

* **ZFA**: Zebrafish Anatomy and Development Ontology (https://obofoundry.org/ontology/zfa.html) - an ontology that describes the anatomy and developmental stages of the zebrafish (*Danio rerio*).

* **XAO**: Xenopus Anatomy Ontology (https://obofoundry.org/ontology/xao.html) - an ontology of the anatomical structures of *Xenopus*.

* **FBBT**: FlyBase Drosophila Gross Anatomy Ontology (https://obofoundry.org/ontology/fbbt.html) - an ontology that describes the gross anatomy of *Drosophila melanogaster*.

* **WBBT**: WormBase Gross Anatomy Ontology (https://obofoundry.org/ontology/wbbt.html) - an ontology that describes the gross anatomy of *Caenorhabditis elegans*.

* **DDANAT**: Dictyostelium Anatomy Ontology (https://obofoundry.org/ontology/ddanat.html) - an ontology of anatomical structures in *Dictyostelium discoideum*.

* **EMAPA**: Mouse Developmental Anatomy Ontology (https://obofoundry.org/ontology/emapa.html) - an ontology that provides a standardized framework for describing spatial and temporal gene expression patterns during mouse development.

### Life Stage Ontologies

* **HsapDv**: Human Developmental Stage Ontology (https://obofoundry.org/ontology/hsapdv.html) - an ontology of human developmental stages, covering both embryonic (Carnegie) stages and adult stages.

## Bridge and Alignment Modules

Bridge ontologies provide the axioms that link species-specific ontologies to their cross-species counterparts, enabling cross-species inference.

* **uPHENO Bridge**: (https://github.com/obophenotype/upheno) - bridge axioms linking species-specific phenotype ontologies to uPHENO.

* **uPHENO Alignments**: (https://github.com/obophenotype/upheno) - alignment axioms for phenotype ontology integration across species.

## SSSOM Mapping Sets

PHENIO includes [Simple Standard for Sharing Ontological Mappings (SSSOM)](https://mapping-commons.github.io/sssom/) mapping sets that define equivalences and relationships between terms in different ontologies.

* **Uberon SSSOM Mappings**: (http://purl.obolibrary.org/obo/uberon/uberon.sssom.tsv) - cross-species anatomy mappings.

* **CL SSSOM Mappings**: (http://purl.obolibrary.org/obo/cl/cl.sssom.tsv) - cell type mappings.

* **uPHENO-OBA SSSOM Mappings**: (https://github.com/obophenotype/upheno) - mappings between uPHENO and OBA.
