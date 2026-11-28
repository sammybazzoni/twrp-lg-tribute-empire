#!/bin/bash
# EXPERIMENT: LineageOS 24.0 recovery for mcv1s. Runs inside an ubuntu:24.04 container.
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive LC_ALL=C.UTF-8 USER=root
export ALLOW_MISSING_DEPENDENCIES=true SOONG_ALLOW_MISSING_DEPENDENCIES=true BUILD_BROKEN_MISSING_REQUIRED_MODULES=true
apt-get update
apt-get install -y bc bison build-essential curl flex g++-multilib gcc-multilib git git-lfs gnupg gperf imagemagick protobuf-compiler python3 python3-protobuf python-is-python3 lib32readline-dev lib32z1-dev libdw-dev libelf-dev libgnutls28-dev lz4 libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc xxd zip unzip zlib1g-dev ca-certificates openssh-client
git config --global user.name build
git config --global user.email build@localhost
git config --global color.ui false
git lfs install
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
chmod +x /usr/local/bin/repo
KIT=$PWD
mkdir -p /lineage && cd /lineage

# Stop before the disk is completely full. A full disk crashes the GitHub runner
# and no error report survives.
echo "starting" > /tmp/stage
largest() {   # one line: the biggest folders, to show where the space went
  du -x -BG --max-depth=2 /lineage 2>/dev/null | sort -rn | head -n 14 | awk '{sub("/lineage/?","",$2); printf "%s %s; ", ($2 ? $2 : "TOTAL"), $1}'
}
(
  while sleep 15; do
    free_gb=$(df --output=avail -BG /lineage | tail -1 | tr -dc '0-9')
    if [ "$free_gb" -lt 4 ]; then
      echo "== disk guard: only ${free_gb} GB free during: $(cat /tmp/stage)"
      echo "BUILD FAILED: the runner is out of disk space during: $(cat /tmp/stage)"
      kill -STOP -1    # pause everything else while measuring
      echo "== disk guard, largest folders: $(largest)"
      kill -KILL -1    # everything in this container except the main script
      exit 1
    fi
  done
) &
echo "== disk before download: $(df -h /lineage | tail -1)"
repo init --depth=1 --git-lfs -u https://github.com/LineageOS/android.git -b lineage-24.0 -g default,-darwin,-mips
mkdir -p .repo/local_manifests
repo manifest > /tmp/full-manifest.xml
python3 "$KIT/trim_manifest.py" /tmp/full-manifest.xml "$KIT/skip-paths.txt" .repo/local_manifests/trim.xml
# Download in batches and delete each batch's Git data as soon as its files are
# unpacked, so the downloads and the unpacked copies never all pile up at once.
repo manifest > /tmp/trimmed-manifest.xml
python3 "$KIT/list_projects.py" /tmp/trimmed-manifest.xml > /tmp/projects.txt
mapfile -t PROJECTS < /tmp/projects.txt
BATCH=25
total=$(( (${#PROJECTS[@]} + BATCH - 1) / BATCH ))
for ((i = 0; i < ${#PROJECTS[@]}; i += BATCH)); do
  n=$(( i / BATCH + 1 ))
  echo "downloading source, batch $n of $total, starting at ${PROJECTS[i]}" > /tmp/stage
  repo sync -c --no-clone-bundle --no-tags -j4 "${PROJECTS[@]:i:BATCH}" ||
    repo sync -c --no-clone-bundle --no-tags -j2 "${PROJECTS[@]:i:BATCH}"
  rm -rf .repo/project-objects/* .repo/projects/*
  echo "-- batch $n of $total done, free: $(df --output=avail -BG /lineage | tail -1 | tr -d ' ')"
done
echo "== disk after download: $(df -h /lineage | tail -1)"
echo "== disk, largest folders: $(largest)"
echo "== memory: $(free -g | awk '/Mem:/{m=$2} /Swap:/{s=$2} END{print m" GB RAM, "s" GB swap"}')"

mkdir -p device/lge && cp -r "$KIT/device/lge/mcv1s" device/lge/
source vendor/lineage/vars/aosp_target_release
set +e
source build/envsetup.sh
set -e
lunch lineage_mcv1s "$aosp_target_release" userdebug
echo "== lunch ok ($aosp_target_release)"
OUT=out/target/product/mcv1s
echo "compiling" > /tmp/stage
m $OUT/ramdisk-recovery.cpio || { echo "== disk at failure: $(df -h /lineage | tail -1)"; echo "BUILD FAILED"; exit 1; }
test -x $OUT/recovery/root/system/bin/recovery || { echo "BUILD FAILED: recovery program is missing."; exit 1; }
cd "$KIT" && python3 pack.py /lineage lineage-recovery-mcv1s-UNTESTED.img
