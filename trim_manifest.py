#!/usr/bin/env python3
"""Write a repo local manifest that skips every project not in keep-paths.txt.

usage: trim_manifest.py <resolved-manifest.xml> <keep-paths.txt> <output.xml>
"""
import sys
import xml.etree.ElementTree as ET

manifest, keep_file, output = sys.argv[1:4]
keep = {l.strip() for l in open(keep_file) if l.strip() and not l.startswith("#")}
projects = [(e.get("name"), e.get("path") or e.get("name"))
            for e in ET.parse(manifest).getroot().iter("project")]
missing = keep - {path for _, path in projects}
if missing:
    sys.exit("Not in the manifest: " + " ".join(sorted(missing)))
kept_names = {name for name, path in projects if path in keep}
drop = sorted({name for name, path in projects if path not in keep})
clash = kept_names & set(drop)
if clash:
    sys.exit("remove-project would also drop a needed project: " + " ".join(sorted(clash)))
root = ET.Element("manifest")
for name in drop:
    ET.SubElement(root, "remove-project", name=name).tail = "\n"
root.text = "\n"
ET.ElementTree(root).write(output, encoding="UTF-8", xml_declaration=True)
print("keeping %d projects, skipping %d" % (len(kept_names), len(drop)))
