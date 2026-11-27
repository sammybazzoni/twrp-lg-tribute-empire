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
