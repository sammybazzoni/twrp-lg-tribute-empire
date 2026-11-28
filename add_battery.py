#!/usr/bin/env python3
"""Add the stock battery service (fuelgauged) to a TWRP image for LG mcv1s.

usage: python3 add_battery.py <stock recovery.bin> <TWRP.img> <output.img>

Needs the lz4 command (sudo apt install lz4) or the Python lz4 module.
It only reads the two input files. It does not touch the phone.
"""
import hashlib, os, shutil, struct, subprocess, sys, tempfile

LIMIT = 22020096                 # recovery partition size
OS_WORD = 0x1004014B             # 8.1.0, patch 2020-11, as in the stock header
FG_SHA = "040db63c7054c51f6a67da1429490c0267132d244705338730d637a8c940cdc4"
LZ4_MAGIC = 0x184C2102
SERVICE = b"""
# --- battery service added by add_battery.py ---
on boot
    start fuelgauged

service fuelgauged /sbin/fuelgauged_static
    user root
    group root
    seclabel u:r:recovery:s0
"""

def pad(n, a):
    return (a - n % a) % a

def decompress(data):
    if len(data) < 8 or struct.unpack_from("<I", data)[0] != LZ4_MAGIC:
        sys.exit("A ramdisk is not LZ4 (legacy). Wrong input file?")
    try:
        import lz4.block
    except ImportError:
        return run_lz4(["-d"], data)
    out, pos = [], 4
    while pos + 4 <= len(data):
        size = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        if size == LZ4_MAGIC:
            continue
        if size == 0 or pos + size > len(data):
            break
        out.append(lz4.block.decompress(data[pos:pos + size], uncompressed_size=8 << 20))
        pos += size
    return b"".join(out)

def compress(data):
    if shutil.which("lz4"):
        return run_lz4(["-l", "-12"], data)
    try:
        import lz4.block
    except ImportError:
        sys.exit("lz4 is not installed: sudo apt install lz4")
    out = [struct.pack("<I", LZ4_MAGIC)]
    for i in range(0, len(data), 8 << 20):
        c = lz4.block.compress(data[i:i + (8 << 20)], mode="high_compression",
                               compression=12, store_size=False)
        out += [struct.pack("<I", len(c)), c]
    return b"".join(out)

def run_lz4(flags, data):
    if not shutil.which("lz4"):
        sys.exit("lz4 is not installed: sudo apt install lz4")
    with tempfile.TemporaryDirectory() as d:
        a, b = os.path.join(d, "in"), os.path.join(d, "out")
        with open(a, "wb") as f:
            f.write(data)
        subprocess.run(["lz4", *flags, "-f", a, b], check=True)
        with open(b, "rb") as f:
            return f.read()

def read_cpio(data):
    entries, pos = [], 0
    while True:
        if data[pos:pos + 6] != b"070701":
            sys.exit("Unexpected ramdisk (cpio) format.")
        fields = [int(data[pos + 6 + 8 * i:pos + 14 + 8 * i], 16) for i in range(13)]
        size, namelen = fields[6], fields[11]
        name = data[pos + 110:pos + 110 + namelen - 1].decode()
        start = pos + 110 + namelen
        start += pad(start, 4)
        if name == "TRAILER!!!":
            return entries
        entries.append([name, fields, data[start:start + size]])
        pos = start + size + pad(start + size, 4)

def write_cpio(entries):
    out = bytearray()
    trailer = ["TRAILER!!!", [0] * 13, b""]
    trailer[1][4] = 1
    for name, fields, body in entries + [trailer]:
        raw = name.encode() + b"\0"
        f = list(fields)
        f[6], f[11] = len(body), len(raw)
        out += b"070701" + b"".join(b"%08x" % v for v in f) + raw
        out += b"\0" * pad(len(out), 4)
        out += body
        out += b"\0" * pad(len(out), 4)
    out += b"\0" * pad(len(out), 256)
    return bytes(out)

def split_image(path):
    with open(path, "rb") as f:
        img = f.read()
    if img[:8] != b"ANDROID!":
        sys.exit(path + " is not an Android boot image.")
    ks, _, rs, _, ss, _, _, page = struct.unpack_from("<8I", img, 8)
    k = page
    r = k + ks + pad(ks, page)
    s = r + rs + pad(rs, page)
    return img[:page], img[k:k + ks], img[r:r + rs], img[s:s + ss], page

def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    stock_path, twrp_path, out_path = sys.argv[1:]
    if os.path.realpath(out_path) in (os.path.realpath(stock_path), os.path.realpath(twrp_path)):
        sys.exit("The output must be a new file, not one of the inputs.")

    stock = {e[0]: e for e in read_cpio(decompress(split_image(stock_path)[2]))}
    fg = stock.get("sbin/fuelgauged_static")
    if not fg or hashlib.sha256(fg[2]).hexdigest() != FG_SHA:
        sys.exit("The first file must be this phone's original stock recovery.bin.")

    header, kernel, ramdisk, second, page = split_image(twrp_path)
    entries = read_cpio(decompress(ramdisk))
    names = {e[0] for e in entries}
    if not any(n.startswith("twres/") for n in names):
        sys.exit("The second file does not look like TWRP.")
    if "sbin/fuelgauged_static" in names:
        sys.exit("This image already has the battery service.")

    # Drop Python and extra languages to make room (same trim as pack.py)
    entries = [e for e in entries if "python" not in e[0]
               and not (e[0].startswith("twres/languages/") and e[0] != "twres/languages/en.xml")]

    rc = [e for e in entries if e[0] == "init.recovery.mcv1s.rc"]
    if not rc:
        sys.exit("init.recovery.mcv1s.rc is missing from the TWRP image.")
    rc[0][2] = rc[0][2].rstrip(b"\n") + b"\n" + SERVICE

    meta = list(fg[1])
    meta[0] = max(e[1][0] for e in entries) + 1   # unused inode number
    meta[1] = 0o100750
    entries.append(["sbin/fuelgauged_static", meta, fg[2]])

    new_rd = compress(write_cpio(entries))
    header = bytearray(header)
    struct.pack_into("<I", header, 16, len(new_rd))
    struct.pack_into("<I", header, 44, OS_WORD)
    sha = hashlib.sha1()
    for part in (kernel, new_rd, second):
        sha.update(part)
        sha.update(struct.pack("<I", len(part)))
    header[576:608] = sha.digest().ljust(32, b"\0")

    out = bytes(header)
    for part in (kernel, new_rd, second):
        out += part + b"\0" * pad(len(part), page)
    if len(out) > LIMIT:
        sys.exit("Result is %d bytes, over the %d byte limit. Nothing written." % (len(out), LIMIT))
    with open(out_path, "wb") as f:
        f.write(out)
    print("Wrote %s: %d bytes (%d free)" % (out_path, len(out), LIMIT - len(out)))

if __name__ == "__main__":
    main()
