#!/usr/bin/env python3
"""Pack the built ramdisk as legacy LZ4 (the only format this kernel supports)."""
import subprocess, sys, os
top = sys.argv[1]
out = top + "/out/target/product/mcv1s"
rd = out + "/ramdisk-recovery.lz4"

def trim(path):
    """Drop Python and non-English languages from the cpio to save space."""
    data = open(path, "rb").read()
    i, kept, dropped = 0, bytearray(), 0
    while data[i:i + 6] == b"070701":
        h = [int(data[i + 6 + 8 * j:i + 14 + 8 * j], 16) for j in range(13)]
        name = data[i + 110:i + 110 + h[11] - 1].decode()
        start = (i + 110 + h[11] + 3) & ~3
        end = (start + h[6] + 3) & ~3
        lang = "twres/languages/" in name and not name.endswith(("/en.xml", "languages/"))
        if "python" in name or lang:
            dropped += 1
        else:
            kept += data[i:end]
        i = end
        if name == "TRAILER!!!":
            break
    else:
        sys.exit("Unexpected cpio format. Nothing packed.")
    kept += b"\0" * (-len(kept) % 512)
    new = path + ".trimmed"
    open(new, "wb").write(kept)
    print("trimmed entries:", dropped)
    return new

cpio = trim(out + "/ramdisk-recovery.cpio")
img = "twrp-mcv1s-UNTESTED.img"
subprocess.check_call(["lz4", "-l", "-12", "-f", cpio, rd])
subprocess.check_call([sys.executable, top + "/system/core/mkbootimg/mkbootimg",
    "--kernel", "device/lge/mcv1s/prebuilt/zImage-dtb", "--ramdisk", rd,
    "--base", "0x40000000", "--pagesize", "2048",
    "--kernel_offset", "0x00008000", "--ramdisk_offset", "0x05000000",
    "--second_offset", "0x00f00000", "--tags_offset", "0x04000000",
    "--os_version", "8.1.0", "--os_patch_level", "2020-11",
    "--cmdline", "bootopt=64S3,32N2,32N2 androidboot.hardware=mcv1s buildvariant=user",
    "-o", img])
size, limit = os.path.getsize(img), 22020096
print("ramdisk:", os.path.getsize(rd), "image:", size, "limit:", limit)
if size > limit:
    os.remove(img)
    sys.exit("TOO BIG by %d bytes; image deleted. Do not flash anything." % (size - limit))
