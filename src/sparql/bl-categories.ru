PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX meta: <https://w3id.org/biolink/biolinkml/meta/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX BFO: <http://purl.obolibrary.org/obo/BFO_>
PREFIX biolink: <https://w3id.org/biolink/vocab/>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX : <..>


INSERT {
  ?subject biolink:category ?biolink_category .
}
WHERE {
  {
    ?biolink_category (skos:exactMatch|skos:narrowMatch)+ ?entity_to_type .
    ?subject (rdf:type|rdfs:subClassOf|owl:equivalentClass|^owl:equivalentClass|owl:sameAs|^owl:sameAs)* ?entity_to_type .
    FILTER(STRSTARTS(str(?biolink_category),"https://w3id.org/biolink/vocab/"))
    FILTER(!STRSTARTS(str(?subject),"https://datacommons.org/browser/"))
    FILTER(!STRSTARTS(str(?subject),"http://semanticscience.org/resource/"))
    FILTER(!STRSTARTS(str(?subject),"http://purl.obolibrary.org/obo/OMIT_"))
    FILTER(isIRI(?subject))
    FILTER(isIRI(?biolink_category))
    FILTER(isIRI(?entity_to_type))
  }
}