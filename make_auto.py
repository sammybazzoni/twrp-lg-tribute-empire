#!/usr/bin/env python3
"""Add automatic /data unlock to a TWRP image for LG mcv1s.

usage: python3 make_auto.py <TWRP.img> <output.img>

Keep add_battery.py, tee-setup.sh and tee-daemon.sh in the same folder.
"""
import hashlib, os, struct, sys

HERE = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, HERE)
import add_battery as ab

RC = b"""
# --- automatic /data unlock added by make_auto.py ---
# init waits for the setup script (it limits its own run time), so the keymaster
# is ready before "on boot" starts TWRP.
on early-boot
    exec u:r:recovery:s0 root root -- /sbin/sh /sbin/tee-setup.sh

service tee_daemon /sbin/sh /sbin/tee-daemon.sh
    user root
    group root
    disabled
    oneshot
    seclabel u:r:recovery:s0
"""

def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, dst = sys.argv[1:]
    if os.path.realpath(src) == os.path.realpath(dst):
        sys.exit("The output must be a new file.")
    header, kernel, ramdisk, second, page = ab.split_image(src)
    entries = ab.read_cpio(ab.decompress(ramdisk))
    by_name = {e[0]: e for e in entries}
    if "sbin/tee-setup.sh" in by_name:
        sys.exit("This image already has the automatic unlock.")
    rc = by_name["init.recovery.mcv1s.rc"]
    rc[2] = rc[2].rstrip(b"\n") + b"\n" + RC
    inode = max(e[1][0] for e in entries)
    for name in ("tee-setup.sh", "tee-daemon.sh"):
        with open(os.path.join(HERE, name), "rb") as f:
            body = f.read()
        inode += 1
        meta = list(by_name["sbin/permissive.sh"][1])
        meta[0], meta[1] = inode, 0o100750
        entries.append(["sbin/" + name, meta, body])
    new_rd = ab.compress(ab.write_cpio(entries))
    header = bytearray(header)
    struct.pack_into("<I", header, 16, len(new_rd))
    sha = hashlib.sha1()
    for part in (kernel, new_rd, second):
        sha.update(part)
        sha.update(struct.pack("<I", len(part)))
    header[576:608] = sha.digest().ljust(32, b"\0")
    out = bytes(header)
    for part in (kernel, new_rd, second):
        out += part + b"\0" * ab.pad(len(part), page)
    if len(out) > ab.LIMIT:
        sys.exit("Result is %d bytes, over the limit. Nothing written." % len(out))
    with open(dst, "wb") as f:
        f.write(out)
    print("Wrote %s: %d bytes (%d free)" % (dst, len(out), ab.LIMIT - len(out)))

if __name__ == "__main__":
    main()
