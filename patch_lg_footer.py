#!/usr/bin/env python3
"""LG's vold stores a 64-byte master key field in the encryption header (AOSP: 48),
which moves every later field by 16 bytes. Widen the field in TWRP to match."""
import sys
path = sys.argv[1] + "/bootable/recovery/crypto/fde/cryptfs.h"
old = "unsigned char master_key[MAX_KEY_LEN]; /* The encrypted key"
new = "unsigned char master_key[MAX_KEY_LEN + 16]; /* LG layout. The encrypted key"
text = open(path).read()
if new in text:
    print("LG header patch already applied")
elif text.count(old) == 1:
    open(path, "w").write(text.replace(old, new))
    print("LG header patch applied")
else:
    sys.exit("cryptfs.h is not what this patch expects. Build stopped.")
