# LineageOS 15.1 recovery for LG Tribute Empire (LM-X220PM, mcv1s)

**Experimental and untested on the phone.** This is a recovery only, not a
LineageOS system ROM. TWRP is on the `main` branch.

## Build on GitHub

Pushing to this branch starts a build. To start one by hand: **Actions**, pick
the build workflow in the left list (it may show the `main` branch's name,
"Build TWRP mcv1s"), **Run workflow**, set **Use workflow from** to
`lineageos`. Download the `lineage-recovery-mcv1s-UNTESTED` artifact.
If a run fails, its log is in the `build-log` artifact.

To fit a GitHub runner, only the source folders in `keep-paths.txt` are
downloaded.

## Build locally

    sudo docker run --rm -v "$PWD:/kit" -w /kit ubuntu:18.04 bash build.sh

## Before flashing

* Keep your original `recovery.bin` and a working TWRP image.
* It cannot decrypt `/data`.
* Do **not** use factory reset or any wipe/format option: it erases data.
* SD card support is untested.
* The kernel is the stock LG kernel with a one-byte touch fix.
