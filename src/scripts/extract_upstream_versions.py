#!/usr/bin/env python3
"""Extract upstream ontology versions for the PHENIO release.

Reads the upstream list from src/ontology/phenio-odk.yaml, fetches each
upstream ontology header (streamed; stops once the <owl:Ontology> block
closes), and emits two artifacts:

  - <tsv-out>: TSV with one row per upstream (id, source_url,
    ontology_iri, version_iri, version_info, retrieved_at).
  - <owl-out>: a tiny RDF/XML "component" whose Ontology subject is the
    PHENIO ontology IRI, with one dcterms:source assertion per upstream
    pointing at that upstream's versionIRI (or, if missing, source_url).

Designed to use bounded memory (~hundreds of KB) regardless of how big
the upstream ontology files are. Typical upstream OWL files declare
versionIRI/versionInfo within the first few KB.
"""

from __future__ import annotations

import argparse
import datetime as dt
import re
import sys
import urllib.request
from pathlib import Path
from xml.etree import ElementTree as ET

import yaml

OWL_NS = "http://www.w3.org/2002/07/owl#"
RDF_NS = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
DCTERMS_NS = "http://purl.org/dc/terms/"
RDFS_NS = "http://www.w3.org/2000/01/rdf-schema#"

PHENIO_ONTOLOGY_IRI = "http://purl.obolibrary.org/obo/phenio.owl"

ONTOLOGY_CLOSE_RE = re.compile(rb"</\s*owl:Ontology\s*>", re.IGNORECASE)
ONTOLOGY_SELF_CLOSE_RE = re.compile(rb"<\s*owl:Ontology\b[^>]*/\s*>", re.IGNORECASE)
# In OWL functional syntax (Manchester/OFN), the ontology block opens with
# `Ontology(...)` and version metadata appears in the first few lines. Stop
# once we've seen at least one Declaration after the Ontology line.
OFN_DECLARATION_RE = re.compile(rb"\bDeclaration\s*\(")
HEADER_BYTE_CAP = 1_048_576  # 1 MiB ceiling per upstream
CHUNK_SIZE = 16_384


def upstream_sources(odk_yaml: Path) -> list[tuple[str, str]]:
    """Return list of (id, url) pairs for every upstream ontology.

    Pulls from both `import_group.products` and `components.products`.
    For imports without a mirror_from override, derives the OBO PURL from
    the id (matches what ODK does when materializing the Makefile).
    """
    cfg = yaml.safe_load(odk_yaml.read_text())
    pairs: list[tuple[str, str]] = []

    for product in cfg.get("components", {}).get("products", []) or []:
        ident = product.get("filename", "").removesuffix(".owl")
        url = product.get("source")
        if ident and url:
            pairs.append((ident, url))

    # Imports without OBO URLs (built from non-OBO sources by custom Makefile
    # rules — phenio.Makefile defines mirror-ncbigene / mirror-hgnc).
    skip_imports = {"ncbigene", "hgnc"}

    for product in cfg.get("import_group", {}).get("products", []) or []:
        ident = product.get("id")
        if not ident or ident in skip_imports:
            continue
        if product.get("mirror_from"):
            url = product["mirror_from"]
        elif product.get("use_base"):
            url = f"http://purl.obolibrary.org/obo/{ident}/{ident}-base.owl"
        else:
            url = f"http://purl.obolibrary.org/obo/{ident}.owl"
        pairs.append((ident, url))

    seen: set[tuple[str, str]] = set()
    deduped: list[tuple[str, str]] = []
    for pair in pairs:
        if pair in seen:
            continue
        seen.add(pair)
        deduped.append(pair)
    return deduped


def fetch_ontology_header(url: str, timeout: int = 60) -> bytes:
    """Stream URL, return bytes through the close of <owl:Ontology>.

    Falls back to whatever was read if the close tag isn't found before
    HEADER_BYTE_CAP — the parser will surface that as a parse error and
    the caller will record empty version fields.
    """
    req = urllib.request.Request(
        url,
        headers={
            "Accept": "application/rdf+xml, */*",
            "User-Agent": "phenio-upstream-versions/1.0 (+https://github.com/monarch-initiative/phenio)",
        },
    )
    buf = bytearray()
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        while len(buf) < HEADER_BYTE_CAP:
            chunk = resp.read(CHUNK_SIZE)
            if not chunk:
                break
            buf.extend(chunk)
            if ONTOLOGY_CLOSE_RE.search(buf) or ONTOLOGY_SELF_CLOSE_RE.search(buf):
                break
            if OFN_DECLARATION_RE.search(buf):
                break
    return bytes(buf)


def parse_header(raw: bytes) -> dict[str, str]:
    """Extract ontology IRI, versionIRI, versionInfo from a header chunk.

    Handles RDF/XML and OWL functional syntax (OFN). Closes the root
    element when needed so ElementTree can parse the truncated stream.
    """
    text = raw.decode("utf-8", errors="replace")

    if text.lstrip().startswith("Prefix(") or re.search(r"^\s*Ontology\s*\(", text, re.MULTILINE):
        return _parse_ofn(text)

    if "</rdf:RDF>" not in text:
        text = text + "\n</rdf:RDF>"

    out = {"ontology_iri": "", "version_iri": "", "version_info": ""}
    try:
        root = ET.fromstring(text)
    except ET.ParseError:
        return _regex_fallback(raw)

    ontology = root.find(f"{{{OWL_NS}}}Ontology")
    if ontology is None:
        return _regex_fallback(raw)

    out["ontology_iri"] = ontology.get(f"{{{RDF_NS}}}about", "") or ""

    version_iri_el = ontology.find(f"{{{OWL_NS}}}versionIRI")
    if version_iri_el is not None:
        out["version_iri"] = version_iri_el.get(f"{{{RDF_NS}}}resource", "") or ""

    version_info_el = ontology.find(f"{{{OWL_NS}}}versionInfo")
    if version_info_el is not None and version_info_el.text:
        out["version_info"] = version_info_el.text.strip()

    return out


def _parse_ofn(text: str) -> dict[str, str]:
    out = {"ontology_iri": "", "version_iri": "", "version_info": ""}

    m = re.search(r"Ontology\s*\(\s*<([^>]+)>(?:\s*<([^>]+)>)?", text)
    if m:
        out["ontology_iri"] = m.group(1) or ""
        out["version_iri"] = (m.group(2) or "")

    m = re.search(r'Annotation\s*\(\s*owl:versionInfo\s+"([^"]+)"', text)
    if m:
        out["version_info"] = m.group(1)
    return out


def _regex_fallback(raw: bytes) -> dict[str, str]:
    text = raw.decode("utf-8", errors="replace")
    out = {"ontology_iri": "", "version_iri": "", "version_info": ""}

    m = re.search(r'<owl:Ontology\b[^>]*\brdf:about="([^"]+)"', text)
    if m:
        out["ontology_iri"] = m.group(1)

    m = re.search(r'<owl:versionIRI\b[^>]*\brdf:resource="([^"]+)"', text)
    if m:
        out["version_iri"] = m.group(1)

    m = re.search(r"<owl:versionInfo[^>]*>([^<]+)</owl:versionInfo>", text)
    if m:
        out["version_info"] = m.group(1).strip()

    return out


def write_tsv(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    cols = ["id", "source_url", "ontology_iri", "version_iri", "version_info", "retrieved_at"]
    with path.open("w", encoding="utf-8") as fh:
        fh.write("\t".join(cols) + "\n")
        for row in rows:
            fh.write("\t".join(row.get(c, "") for c in cols) + "\n")


def write_owl_component(path: Path, rows: list[dict[str, str]], phenio_iri: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    ET.register_namespace("owl", OWL_NS)
    ET.register_namespace("rdf", RDF_NS)
    ET.register_namespace("rdfs", RDFS_NS)
    ET.register_namespace("dcterms", DCTERMS_NS)

    rdf = ET.Element(f"{{{RDF_NS}}}RDF")
    ontology = ET.SubElement(rdf, f"{{{OWL_NS}}}Ontology", {f"{{{RDF_NS}}}about": phenio_iri})
    comment = ET.SubElement(ontology, f"{{{RDFS_NS}}}comment")
    comment.text = (
        "Upstream ontology versions used in this PHENIO release. Each "
        "dcterms:source links to the versionIRI of the upstream artifact "
        "consumed at build time. Generated by "
        "src/scripts/extract_upstream_versions.py."
    )

    for row in rows:
        target = row.get("version_iri") or row.get("source_url")
        if not target:
            continue
        ET.SubElement(
            ontology,
            f"{{{DCTERMS_NS}}}source",
            {f"{{{RDF_NS}}}resource": target},
        )

    ET.indent(rdf, space="    ")
    tree = ET.ElementTree(rdf)
    with path.open("wb") as fh:
        fh.write(b'<?xml version="1.0"?>\n')
        tree.write(fh, encoding="utf-8", xml_declaration=False)
        fh.write(b"\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--odk-yaml", type=Path, required=True)
    parser.add_argument("--tsv-out", type=Path, required=True)
    parser.add_argument("--owl-out", type=Path, required=True)
    parser.add_argument("--phenio-iri", default=PHENIO_ONTOLOGY_IRI)
    parser.add_argument("--limit", type=int, default=0, help="If >0, only process the first N upstreams (for local testing).")
    parser.add_argument("--only", default="", help="Comma-separated list of ids to process (overrides --limit).")
    args = parser.parse_args(argv)

    sources = upstream_sources(args.odk_yaml)
    if args.only:
        wanted = {s.strip() for s in args.only.split(",") if s.strip()}
        sources = [p for p in sources if p[0] in wanted]
    elif args.limit > 0:
        sources = sources[: args.limit]

    rows: list[dict[str, str]] = []
    for ident, url in sources:
        retrieved = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        row = {"id": ident, "source_url": url, "retrieved_at": retrieved}
        try:
            raw = fetch_ontology_header(url)
            row.update(parse_header(raw))
            print(
                f"[ok] {ident}\tversion_iri={row['version_iri']!r}\tversion_info={row['version_info']!r}",
                file=sys.stderr,
            )
        except Exception as exc:  # noqa: BLE001
            row.update({"ontology_iri": "", "version_iri": "", "version_info": ""})
            print(f"[fail] {ident} ({url}): {exc}", file=sys.stderr)
        rows.append(row)

    write_tsv(args.tsv_out, rows)
    write_owl_component(args.owl_out, rows, args.phenio_iri)
    print(
        f"Wrote {args.tsv_out} ({len(rows)} rows) and {args.owl_out}",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
