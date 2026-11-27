# TWRP build kit: LG Tribute Empire (mcv1s, X220PM19g). UNTESTED

## Build
1. Create a new GitHub repository.
2. Upload the CONTENTS of this folder, including the hidden `.github` folder
   (`git add .` includes it).
3. Actions tab > "Build TWRP mcv1s" > Run workflow.
4. On success, download the `twrp-mcv1s-UNTESTED` artifact.
   On failure, send the log of the "Build" step for fixes.

## Before flashing
Send the built .img back for inspection. Do not flash it first.
Keep the original recovery.bin and a full backup, and confirm you can restore.

## Known limits
- Never built or booted.
- Decryption is stage 1 only: TWRP's crypto code is enabled, but the phone's
  Trustonic/Keymaster services are not started yet. Do not expect /data to unlock.
- pack.py removes Python and non-English languages.
- The kernel has a one-byte patch so touch initializes in recovery.
- Image may not fit: the kernel needs LZ4, which compresses less than LZMA.
  pack.py deletes any oversized image.
- Backlight path and SD/USB device paths are assumed, not verified.
- prebuilt/zImage-dtb and init.recovery.mcv1s.rc come from the stock recovery.

## LG encryption header (TWRP, untested on the phone)

The phone's `vold` uses a 64-byte master key field where AOSP uses 48, so the
salt, KDF type and keymaster blob sit 16 bytes later. `patch_lg_footer.py`
makes TWRP read that layout. This alone is **not expected to unlock /data**:
if the phone uses a keymaster KDF, Trustonic services must also run in TWRP,
and they are not set up yet.

## LineageOS 15.1 recovery (untested, never built)

This is a recovery only, not a LineageOS system ROM. Run on a Linux PC with Docker:

    bash lineage/build-lineage.sh /path/to/big/disk/lineage-mcv1s

It downloads the LineageOS 15.1 source and writes
`lineage-recovery-mcv1s-UNTESTED.img` to this folder. The script asks for
100 GB free (an estimate, not measured). Re-running reuses the download.
You may need `sudo` if your user cannot run Docker.

* It has no `/data` decryption.
* Do **not** use factory reset or any wipe/format option: it erases data.
* SD card support is untested.
