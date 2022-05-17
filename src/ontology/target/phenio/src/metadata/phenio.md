---
layout: ontology_detail
id: phenio
title: Phenomics Integrated Ontology
jobs:
  - id: https://travis-ci.org/monarch-initiative/phenio
    type: travis-ci
build:
  checkout: git clone https://github.com/monarch-initiative/phenio.git
  system: git
  path: "."
contact:
  email: 
  label: 
  github: 
description: Phenomics Integrated Ontology is an ontology...
domain: stuff
homepage: https://github.com/monarch-initiative/phenio
products:
  - id: phenio.owl
    name: "Phenomics Integrated Ontology main release in OWL format"
  - id: phenio.obo
    name: "Phenomics Integrated Ontology additional release in OBO format"
  - id: phenio.json
    name: "Phenomics Integrated Ontology additional release in OBOJSon format"
  - id: phenio/phenio-base.owl
    name: "Phenomics Integrated Ontology main release in OWL format"
  - id: phenio/phenio-base.obo
    name: "Phenomics Integrated Ontology additional release in OBO format"
  - id: phenio/phenio-base.json
    name: "Phenomics Integrated Ontology additional release in OBOJSon format"
dependencies:
- id: nbo
- id: fao
- id: oba
- id: stato
- id: bfo
- id: hsapdv
- id: mpath
- id: ncbitaxon-taxslim
- id: caro
- id: uberon
- id: uberon-bridge-to-zfa
- id: uberon-bridge-to-ma
- id: uberon-bridge-to-wbbt
- id: uberon-bridge-to-fbbt
- id: uberon-bridge-to-fma
- id: uberon-bridge-to-nifstd
- id: cl-bridge-to-ma
- id: cl-bridge-to-fma
- id: cl-bridge-to-wbbt
- id: cl-bridge-to-fbbt
- id: cl-bridge-to-zfa

tracker: https://github.com/monarch-initiative/phenio/issues
license:
  url: http://creativecommons.org/licenses/by/3.0/
  label: CC-BY
activity_status: active
---

Enter a detailed description of your ontology here. You can use arbitrary markdown and HTML.
You can also embed images too.

