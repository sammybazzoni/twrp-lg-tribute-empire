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
Keep the original recovery.bin and a working TWRP image, and confirm you can restore.

## Battery (run on your PC after building)
The battery program comes from your own stock recovery, so it is not in this
repository. Add it to the downloaded image (needs `sudo apt install lz4`):

    python3 add_battery.py recovery.bin twrp-mcv1s-UNTESTED.img twrp-final.img

## Unlocking /data
`patch_lg_footer.py` makes two changes, both read from the phone's own `vold`:
the header layout (64-byte master key field) and the key sizes (AES-256 with 48
bytes of derived key material, where AOSP uses AES-128 and 32).

`make_auto.py` adds `tee-setup.sh` and `tee-daemon.sh` to the image. Before TWRP
starts, they mount vendor, system and persist_lg read-only, copy the phone's
Trustonic files into RAM and start the Trustonic service. The log is
`/tmp/tee-setup.log`.

Status:
- Unlocking with Android's default password worked on the phone, using a manual
  version of these startup steps.
- The automatic startup has only been dry-run, not confirmed on the phone.
- Entering a PIN (storage encrypted with a PIN) is untested.
- While storage uses the default password, TWRP unlocks without asking, so anyone
  who can start TWRP on the phone can read the files.

Do not wipe or format /data.

## Known limits
- Touch and the battery level were confirmed working on the phone (battery after
  running add_battery.py).
- pack.py removes Python and non-English languages.
- The kernel has a one-byte patch so touch initializes in recovery.
- The kernel needs LZ4, which compresses less than LZMA. pack.py deletes any
  oversized image.
- Backlight path and SD/USB device paths are assumed, not verified.
- prebuilt/zImage-dtb and init.recovery.mcv1s.rc come from the stock recovery.

## LineageOS recovery

LineageOS has its own workflow, separate from TWRP:
Actions tab > "Build LineageOS recovery mcv1s" > Run workflow. Leave "Use
workflow from" on `main` and pick a version:

- `15.1` builds from the `lineageos` branch. It has built successfully.
- `24.0 (experimental)` builds from the `lineageos-24` branch. It may not build
  or boot.

Neither has been tested on the phone. Send the .img for checking before flashing.
