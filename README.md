# EXPERIMENT: LineageOS 24.0 recovery for mcv1s

This branch tries to build the newest LineageOS recovery. It may not build, and
even if it builds it may not boot: the phone has a 3.18 kernel. The 15.1
recovery is on the `lineageos` branch; TWRP is on `main`.

`skip-paths.txt` lists the source left out to fit a GitHub runner. The source is
downloaded in batches, deleting each batch's Git data to save disk space.
Do not flash any result before it has been checked.
