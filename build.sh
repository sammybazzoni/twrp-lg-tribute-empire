#!/bin/bash
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive LC_ALL=C USER=root ALLOW_MISSING_DEPENDENCIES=true
apt-get update
apt-get install -y openjdk-8-jdk git curl python python3 bc bison build-essential flex g++-multilib gcc-multilib gnupg gperf lib32ncurses5-dev lib32z1-dev libncurses5 libssl-dev libxml2-utils xsltproc zip unzip zlib1g-dev rsync liblz4-tool ca-certificates
git config --global user.name build
git config --global user.email build@localhost
git config --global color.ui false
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
chmod +x /usr/local/bin/repo
KIT=$PWD
mkdir -p /twrp && cd /twrp
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_omni.git -b twrp-8.1
repo sync -c --no-clone-bundle --no-tags -j4
python3 "$KIT/patch_lg_footer.py" /twrp
mkdir -p device/lge && cp -r "$KIT/device/lge/mcv1s" device/lge/
set +e
source build/envsetup.sh
set -e
lunch omni_mcv1s-eng
# The stock-style gzip image may exceed the size limit; only the cpio is needed.
mka recoveryimage || echo "build step reported an error; checking for ramdisk"
test -s out/target/product/mcv1s/ramdisk-recovery.cpio
cd "$KIT" && python3 pack.py /twrp

# Add the automatic /data unlock. The phone's own Trustonic files are copied at
# each TWRP startup, so none of them are in this repository or in the image.
python3 make_auto.py twrp-mcv1s-UNTESTED.img twrp-auto.tmp
mv twrp-auto.tmp twrp-mcv1s-UNTESTED.img
