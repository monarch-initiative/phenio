# Repository structure

The main kinds of files in the repository:

1. Release files
2. Imports
3. [Components](#components)

## Release files
Release file are the file that are considered part of the official ontology release and to be used by the community. A detailed description of the release artefacts can be found [here](https://github.com/INCATools/ontology-development-kit/blob/master/docs/ReleaseArtefacts.md).

## Imports
Imports are subsets of external ontologies that contain terms and axioms you would like to re-use in your ontology. These are considered "external", like dependencies in software development, and are not included in your "base" product, which is the [release artefact](https://github.com/INCATools/ontology-development-kit/blob/master/docs/ReleaseArtefacts.md) which contains only those axioms that you personally maintain.

These are the current imports in PHENIO

| Import | URL | Type |
| ------ | --- | ---- |
| monochrom | https://raw.githubusercontent.com/monarch-initiative/monochrom/refs/heads/master/chr-base.owl | None |
| ncbigene | http://purl.obolibrary.org/obo/ncbigene.owl | None |
| hgnc | http://purl.obolibrary.org/obo/hgnc.owl | None |
| so | http://purl.obolibrary.org/obo/so.owl | None |
| bspo | http://purl.obolibrary.org/obo/bspo.owl | None |
| wbls | http://purl.obolibrary.org/obo/wbls.owl | None |
| zfs | http://purl.obolibrary.org/obo/zfa.owl | None |
| fbdv | http://purl.obolibrary.org/obo/fbdv.owl | None |
| chebi | https://raw.githubusercontent.com/obophenotype/chebi_obo_slim/main/chebi_slim.owl | None |
| pr | https://raw.githubusercontent.com/obophenotype/pro_obo_slim/master/pr_slim.owl | None |
| eco | http://purl.obolibrary.org/obo/eco.owl | None |
| bfo | http://purl.obolibrary.org/obo/bfo.owl | None |
| ro | http://purl.obolibrary.org/obo/ro.owl | None |
| ncbitaxon-taxslim | http://purl.obolibrary.org/obo/ncbitaxon/subsets/taxslim.owl | None |
| pato | http://purl.obolibrary.org/obo/pato.owl | None |
| mpath | http://purl.obolibrary.org/obo/mpath.owl | None |
| nbo | http://purl.obolibrary.org/obo/nbo.owl | None |
| upheno-bridge | https://raw.githubusercontent.com/obophenotype/upheno-dev/refs/heads/master/src/ontology/components/upheno-bridge.owl | None |
| upheno-alignments | https://raw.githubusercontent.com/obophenotype/upheno-dev/refs/heads/master/src/ontology/components/upheno-alignments.owl | None |

## Components
Components, in contrast to imports, are considered full members of the ontology. This means that any axiom in a component is also included in the ontology base - which means it is considered _native_ to the ontology. While this sounds complicated, consider this: conceptually, no component should be part of more than one ontology. If that seems to be the case, we are most likely talking about an import. Components are often not needed for ontologies, but there are some use cases:

1. There is an automated process that generates and re-generates a part of the ontology
2. A part of the ontology is managed in ROBOT templates
3. The expressivity of the component is higher than the format of the edit file. For example, people still choose to manage their ontology in OBO format (they should not) missing out on a lot of owl features. They may choose to manage logic that is beyond OBO in a specific OWL component.

These are the components in PHENIO

| Filename | URL |
| -------- | --- |
| go.owl | http://purl.obolibrary.org/obo/go/go-base.owl |
| mondo.owl | http://purl.obolibrary.org/obo/mondo/mondo-base.owl |
| maxo.owl | http://purl.obolibrary.org/obo/maxo/maxo-base.owl |
| upheno.owl | https://github.com/obophenotype/upheno-dev/releases/latest/download/upheno-base.owl |
| oba.owl | http://purl.obolibrary.org/obo/oba/oba-base.owl |
| hp.owl | http://purl.obolibrary.org/obo/hp/hp-base.owl |
| fypo.owl | http://purl.obolibrary.org/obo/fypo/fypo-base.owl |
| zp.owl | http://purl.obolibrary.org/obo/zp/zp-base.owl |
| xpo.owl | http://purl.obolibrary.org/obo/xpo/xpo-base.owl |
| mp.owl | http://purl.obolibrary.org/obo/mp/mp-base.owl |
| wbphenotype.owl | http://purl.obolibrary.org/obo/wbphenotype/wbphenotype-base.owl |
| ddpheno.owl | http://purl.obolibrary.org/obo/ddpheno/ddpheno-base.owl |
| dpo.owl | http://purl.obolibrary.org/obo/dpo/dpo-base.owl |
| uberon.owl | http://purl.obolibrary.org/obo/uberon/uberon-base.owl |
| cl.owl | http://purl.obolibrary.org/obo/cl/cl-base.owl |
| ddanat.owl | http://purl.obolibrary.org/obo/ddanat.owl |
| wbbt.owl | http://purl.obolibrary.org/obo/wbbt.owl |
| fbbt.owl | http://purl.obolibrary.org/obo/fbbt.owl |
| zfa.owl | http://purl.obolibrary.org/obo/zfa.owl |
| xao.owl | http://purl.obolibrary.org/obo/xao.owl |
| emapa.owl | http://purl.obolibrary.org/obo/emapa.owl |
| hsapdv.owl | http://purl.obolibrary.org/obo/hsapdv.owl |
