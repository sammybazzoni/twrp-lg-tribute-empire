#!/usr/bin/env python3
"""Show the key lines of a failed build log as GitHub annotations."""
import re, sys
lines = open(sys.argv[1], errors="replace").read().splitlines()
pattern = re.compile(r"\berror:|\*\*\*|FAILED:|BUILD FAILED|^fatal:|No space left|ninja failed|"
                     r"No rule to make|Traceback|Not in the manifest|SyncError|Cannot fetch")
hits = [l for l in lines if pattern.search(l)]
steps = [l for l in lines if l.startswith(("keeping ", "== disk", "lunch", "TARGET_PRODUCT", "/dev/"))]

def note(title, body):
    text = "\n".join(x[:400] for x in body)[-3800:] or "(nothing matched)"
    text = text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print("::error title=%s::%s" % (title, text))

note("Progress", steps[:20])
note("First errors", "\n".join(x[:400] for x in hits[:25])[:3800].split("\n"))
note("Last errors", hits[-15:])
note("End of log", lines[-30:])
