#!/usr/bin/env python3
"""Make TWRP read and unlock this phone's LG flavour of Android full-disk encryption.

Both differences were read from the phone's own /system/bin/vold:
1. Header: the master key field is 64 bytes (AOSP: 48), so every later field
   sits 16 bytes further on.
2. Keys: the master key is 256-bit and wrapped with AES-256-CBC. The key
   derivation produces 48 bytes (32 key + 16 IV); AOSP uses AES-128 and 32.
"""
import sys

fde = sys.argv[1] + "/bootable/recovery/crypto/fde/"
PATCHES = {
    "cryptfs.h": [
        ("unsigned char master_key[MAX_KEY_LEN]; /* The encrypted key",
         "unsigned char master_key[MAX_KEY_LEN + 16]; /* LG layout. The encrypted key"),
    ],
    "cryptfs.cpp": [
        ("constexpr size_t INTERMEDIATE_KEY_LEN_BYTES = 16;",
         "constexpr size_t INTERMEDIATE_KEY_LEN_BYTES = 32; /* LG: AES-256 */"),
        # SCRYPT_LEN (the check value stored in the header) stays 32.
        ("static_assert(INTERMEDIATE_BUF_SIZE == SCRYPT_LEN,",
         "static_assert(INTERMEDIATE_KEY_LEN_BYTES == SCRYPT_LEN,"),
        ("EVP_DecryptInit_ex(&d_ctx, EVP_aes_128_cbc(), NULL,",
         "EVP_DecryptInit_ex(&d_ctx, EVP_aes_256_cbc(), NULL,"),
    ],
}

results = {}
for name, edits in PATCHES.items():
    text = open(fde + name).read()
    for old, new in edits:
        if new in text:
            continue
        if text.count(old) != 1:
            sys.exit("%s is not what this patch expects (%r). Build stopped." % (name, old))
        text = text.replace(old, new)
    results[name] = text
# Write only after every edit has matched.
for name, text in results.items():
    open(fde + name, "w").write(text)
print("LG encryption patch applied")
