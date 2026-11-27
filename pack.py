#!/usr/bin/env python3
"""Pack the built ramdisk as legacy LZ4 (the only format this kernel supports)."""
import subprocess, sys, os
top = sys.argv[1]
out = top + "/out/target/product/mcv1s"
rd = out + "/ramdisk-recovery.lz4"
img = "twrp-mcv1s-UNTESTED.img"
subprocess.check_call(["lz4", "-l", "-12", "-f", out + "/ramdisk-recovery.cpio", rd])
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
