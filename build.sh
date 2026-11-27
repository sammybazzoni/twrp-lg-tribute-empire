#!/bin/bash
# Build LineageOS 15.1 recovery for mcv1s. Runs inside an ubuntu:18.04 container.
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive LC_ALL=C USER=root ALLOW_MISSING_DEPENDENCIES=true
apt-get update
apt-get install -y openjdk-8-jdk git curl python python3 bc bison build-essential flex g++-multilib gcc-multilib gnupg gperf lib32ncurses5-dev lib32z1-dev libncurses5 libssl-dev libxml2-utils xsltproc zip unzip zlib1g-dev rsync liblz4-tool ca-certificates schedtool lzop
git config --global user.name build
git config --global user.email build@localhost
git config --global color.ui false
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
chmod +x /usr/local/bin/repo
KIT=$PWD
mkdir -p /lineage && cd /lineage
repo init --depth=1 -u https://github.com/LineageOS/android.git -b lineage-15.1 -g default,-darwin,-mips
mkdir -p .repo/local_manifests
repo manifest > /tmp/full-manifest.xml
python3 "$KIT/trim_manifest.py" /tmp/full-manifest.xml "$KIT/keep-paths.txt" .repo/local_manifests/trim.xml
repo sync -c --no-clone-bundle --no-tags -j4
echo "== disk after download"; df -h /lineage

mkdir -p device/lge && cp -r "$KIT/device/lge/mcv1s" device/lge/
set +e
source build/envsetup.sh
set -e
lunch lineage_mcv1s-userdebug
# The gzip image may exceed the size limit; only the cpio is needed.
mka recoveryimage || echo "build step reported an error; checking for ramdisk"
OUT=out/target/product/mcv1s
test -s $OUT/ramdisk-recovery.cpio || { echo "BUILD FAILED: no recovery ramdisk."; exit 1; }
for f in recovery minivold adbd mke2fs_static; do
    test -x $OUT/recovery/root/sbin/$f || { echo "BUILD FAILED: sbin/$f is missing."; exit 1; }
done
cd "$KIT" && python3 pack.py /lineage lineage-recovery-mcv1s-UNTESTED.img
