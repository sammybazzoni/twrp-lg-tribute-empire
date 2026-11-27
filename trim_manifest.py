#!/usr/bin/env python3
"""Write a repo local manifest that skips projects a recovery build should not need.

usage: trim_manifest.py <resolved-manifest.xml> <skip-paths.txt> <output.xml>
Each line of skip-paths.txt is a regular expression matched against the start
of a project path. Lines starting with ! are exceptions that are kept.
"""
import re, sys
import xml.etree.ElementTree as ET

manifest, rules_file, output = sys.argv[1:4]
rules = [l.strip() for l in open(rules_file) if l.strip() and not l.startswith("#")]
skip = [re.compile(r) for r in rules if not r.startswith("!")]
keep = [re.compile(r[1:]) for r in rules if r.startswith("!")]

def skipped(path):
    return any(r.match(path) for r in skip) and not any(r.match(path) for r in keep)

projects = [(e.get("name"), e.get("path") or e.get("name"))
            for e in ET.parse(manifest).getroot().iter("project")]
kept = {name for name, path in projects if not skipped(path)}
drop = sorted({name for name, path in projects if skipped(path)} - kept)
root = ET.Element("manifest")
for name in drop:
    ET.SubElement(root, "remove-project", name=name).tail = "\n"
root.text = "\n"
ET.ElementTree(root).write(output, encoding="UTF-8", xml_declaration=True)
print("keeping %d projects, skipping %d" % (len(kept), len(drop)))
