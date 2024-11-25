PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

INSERT {
  ?emapaIri rdfs:subClassOf <http://data.monarchinitiative.org/vocab/PHENIO_EMAPA_ROOT> .
  <http://data.monarchinitiative.org/vocab/PHENIO_EMAPA_ROOT>  rdfs:label "EMAPA root (PHENIO)"@en .
}
WHERE {
  ?emapaIri a owl:Class .
  FILTER NOT EXISTS {
    ?emapaIri rdfs:subClassOf ?superClass .
    FILTER(isIRI(?superClass))
  }
  FILTER(STRSTARTS(STR(?emapaIri), "http://purl.obolibrary.org/obo/EMAPA_"))
}
