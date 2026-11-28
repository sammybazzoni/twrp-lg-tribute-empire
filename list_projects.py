#!/usr/bin/env python3
"""Print the project paths that `repo sync` would download, sorted by path.

usage: list_projects.py <resolved-manifest.xml>
`repo list` only shows projects already on disk, so read the manifest instead.
Matches the groups given to `repo init`: default,-darwin,-mips on Linux.
"""
import sys
import xml.etree.ElementTree as ET

paths = []
for project in ET.parse(sys.argv[1]).getroot().iter("project"):
    groups = set((project.get("groups") or "").replace(",", " ").split())
    if groups & {"darwin", "mips"}:
        continue
    if "notdefault" in groups and "platform-linux" not in groups:
        continue
    paths.append(project.get("path") or project.get("name"))
# Parents sort before the projects nested inside them.
print("\n".join(sorted(paths)))
