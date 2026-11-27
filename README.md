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
- No /data decryption support configured.
- Image may not fit: the kernel needs LZ4, which compresses less than LZMA.
  pack.py deletes any oversized image.
- Backlight path and SD/USB device paths are assumed, not verified.
- prebuilt/zImage-dtb and init.recovery.mcv1s.rc come from the stock recovery.
