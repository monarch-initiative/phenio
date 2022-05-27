# Repository structure

The main kinds of files in the repository:

1. Release files
2. Imports
3. [Components](#Components)

## Release files
Release file are the file that are considered part of the official ontology release and to be used by the community. A detailed descripts of the release artefacts can be found [here](https://github.com/INCATools/ontology-development-kit/blob/master/docs/ReleaseArtefacts.md).

## Imports
Imports are subsets of external ontologies that contain terms and axioms you would like to re-use in your ontology. These are considered "external", like dependencies in software development, and are not included in your "base" product, which is the [release artefact](https://github.com/INCATools/ontology-development-kit/blob/master/docs/ReleaseArtefacts.md) which contains only those axioms that you personally maintain.

These are the current imports in PHENIO

| Import | URL | Type |
| ------ | --- | ---- |
| nbo | http://purl.obolibrary.org/obo/nbo.owl | None |
| fao | http://purl.obolibrary.org/obo/fao.owl | None |
| oba | http://purl.obolibrary.org/obo/oba.owl | None |
| stato | http://purl.obolibrary.org/obo/stato.owl | None |
| bfo | http://purl.obolibrary.org/obo/bfo.owl | None |
| hsapdv | http://purl.obolibrary.org/obo/hsapdv.owl | None |
| mpath | http://purl.obolibrary.org/obo/mpath.owl | None |
| ncbitaxon-taxslim | http://purl.obolibrary.org/obo/ncbitaxon/subsets/taxslim.owl | None |
| caro | http://purl.obolibrary.org/obo/caro.owl | None |
| uberon | http://purl.obolibrary.org/obo/uberon.owl | None |
| uberon-bridge-to-zfa | http://purl.obolibrary.org/obo/uberon/bridge/uberon-bridge-to-zfa.owl | None |
| uberon-bridge-to-ma | http://purl.obolibrary.org/obo/uberon/bridge/uberon-bridge-to-ma.owl | None |
| uberon-bridge-to-wbbt | http://purl.obolibrary.org/obo/uberon/bridge/uberon-bridge-to-wbbt.owl | None |
| uberon-bridge-to-fbbt | http://purl.obolibrary.org/obo/uberon/bridge/uberon-bridge-to-fbbt.owl | None |
| uberon-bridge-to-fma | http://purl.obolibrary.org/obo/uberon/bridge/uberon-bridge-to-fma.owl | None |
| uberon-bridge-to-nifstd | http://purl.obolibrary.org/obo/uberon/bridge/uberon-bridge-to-nifstd.owl | None |
| cl-bridge-to-ma | http://purl.obolibrary.org/obo/uberon/bridge/cl-bridge-to-ma.owl | None |
| cl-bridge-to-fma | http://purl.obolibrary.org/obo/uberon/bridge/cl-bridge-to-fma.owl | None |
| cl-bridge-to-wbbt | http://purl.obolibrary.org/obo/uberon/bridge/cl-bridge-to-wbbt.owl | None |
| cl-bridge-to-fbbt | http://purl.obolibrary.org/obo/uberon/bridge/cl-bridge-to-fbbt.owl | None |
| cl-bridge-to-zfa | http://purl.obolibrary.org/obo/uberon/bridge/cl-bridge-to-zfa.owl | None |

## Components
Components, in contrast to imports, are considered full members of the ontology. This means that any axiom in a component is also included in the ontology base - which means it is considered _native_ to the ontology. While this sounds complicated, consider this: conceptually, no component should be part of more than one ontology. If that seems to be the case, we are most likely talking about an import. Components are often not needed for ontologies, but there are some use cases:

1. There is an automated process that generates and re-generates a part of the ontology
2. A part of the ontology is managed in ROBOT templates
3. The expressivity of the component is higher than the format of the edit file. For example, people still choose to manage their ontology in OBO format (they should not) missing out on a lot of owl features. They may chose to manage logic that is beyond OBO in a specific OWL component.

These are the components in PHENIO

| Filename | URL |
| -------- | --- |
| pato.owl | http://purl.obolibrary.org/obo/pato/pato-base.owl |
| go.owl | http://purl.obolibrary.org/obo/go/go-base.owl |
| upheno.owl | https://bbop-ontologies.s3.amazonaws.com/upheno/current/upheno-release/all/upheno_all_with_relations.owl |
| mondo-equivalents.owl | http://purl.obolibrary.org/obo/mondo/imports/equivalencies.owl |
| mondo.owl | http://purl.obolibrary.org/obo/mondo/mondo-base.owl |
| eco.owl | http://purl.obolibrary.org/obo/eco/eco-base.owl |
| sepio.owl | http://purl.obolibrary.org/obo/sepio.owl |
| ro.owl | http://purl.obolibrary.org/obo/ro.owl |
| uberon.owl | http://purl.obolibrary.org/obo/uberon/uberon-base.owl |
| fbbt.owl | http://purl.obolibrary.org/obo/fbbt/fbbt-base.owl |
| wbbt.owl | http://purl.obolibrary.org/obo/wbbt/wbbt-base.owl |
| zfa.owl | http://purl.obolibrary.org/obo/zfa/zfa-base.owl |
| chebi.owl | None |
