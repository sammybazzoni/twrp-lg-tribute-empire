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
repo init --depth=1 --git-lfs -u https://github.com/LineageOS/android.git -b lineage-24.0 -g default,-darwin,-mips
mkdir -p .repo/local_manifests
repo manifest > /tmp/full-manifest.xml
python3 "$KIT/trim_manifest.py" /tmp/full-manifest.xml "$KIT/skip-paths.txt" .repo/local_manifests/trim.xml
repo sync -c --no-clone-bundle --no-tags -j4
echo "== disk after download: $(df -h /lineage | tail -1)"
echo "== memory: $(free -g | awk '/Mem:/{m=$2} /Swap:/{s=$2} END{print m" GB RAM, "s" GB swap"}')"

mkdir -p device/lge && cp -r "$KIT/device/lge/mcv1s" device/lge/
source vendor/lineage/vars/aosp_target_release
set +e
source build/envsetup.sh
set -e
lunch lineage_mcv1s "$aosp_target_release" userdebug
echo "== lunch ok ($aosp_target_release)"
OUT=out/target/product/mcv1s
m $OUT/ramdisk-recovery.cpio || { echo "== disk at failure: $(df -h /lineage | tail -1)"; echo "BUILD FAILED"; exit 1; }
test -x $OUT/recovery/root/system/bin/recovery || { echo "BUILD FAILED: recovery program is missing."; exit 1; }
cd "$KIT" && python3 pack.py /lineage lineage-recovery-mcv1s-UNTESTED.img
