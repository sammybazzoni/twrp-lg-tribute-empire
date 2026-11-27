#!/bin/bash
# Build LineageOS 15.1 recovery for mcv1s on a Linux PC. Needs Docker.
# Usage:  bash lineage/build-lineage.sh [work-directory]
set -eo pipefail

if [ "$1" != "--inside" ]; then
    KIT=$(cd "$(dirname "$0")/.." && pwd)
    WORK=${1:-$HOME/lineage-mcv1s}
    command -v docker >/dev/null || { echo "Docker is not installed."; exit 1; }
    mkdir -p "$WORK"
    WORK=$(cd "$WORK" && pwd)
    FREE=$(df -BG --output=avail "$WORK" | tail -1 | tr -dc 0-9)
    MIN_GB=${MIN_GB:-100}
    # Only the first run needs the full amount; later runs reuse the download.
    if [ ! -d "$WORK/.repo" ] && [ "$FREE" -lt "$MIN_GB" ]; then
        echo "Only ${FREE} GB free in $WORK; this script asks for ${MIN_GB} GB (a cautious estimate)."
        echo "Pass a directory on a bigger disk, or set MIN_GB lower at your own risk."
        exit 1
    fi
    exec docker run --rm -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
        -v "$KIT:/kit" -v "$WORK:/lineage" ubuntu:18.04 bash /kit/lineage/build-lineage.sh --inside
fi

export DEBIAN_FRONTEND=noninteractive LC_ALL=C USER=root ALLOW_MISSING_DEPENDENCIES=true
# Hand the image back to the person who started the build
trap 'chown "$HOST_UID:$HOST_GID" /kit/lineage-recovery-mcv1s-UNTESTED.img 2>/dev/null || true' EXIT
apt-get update
apt-get install -y openjdk-8-jdk git curl python python3 bc bison build-essential flex g++-multilib gcc-multilib gnupg gperf lib32ncurses5-dev lib32z1-dev libncurses5 libssl-dev libxml2-utils xsltproc zip unzip zlib1g-dev rsync liblz4-tool ca-certificates schedtool lzop
git config --global user.name build
git config --global user.email build@localhost
git config --global color.ui false
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
chmod +x /usr/local/bin/repo
cd /lineage
repo init --depth=1 -u https://github.com/LineageOS/android.git -b lineage-15.1 -g default,-darwin,-mips
repo sync -c --no-clone-bundle --no-tags -j4

rm -rf device/lge/mcv1s
mkdir -p device/lge
cp -r /kit/lineage/device/lge/mcv1s device/lge/
mkdir -p device/lge/mcv1s/prebuilt
cp /kit/device/lge/mcv1s/prebuilt/zImage-dtb device/lge/mcv1s/prebuilt/

# Never pack a ramdisk left over from an earlier run
rm -f out/target/product/mcv1s/ramdisk-recovery.cpio
set +e
source build/envsetup.sh
set -e
lunch lineage_mcv1s-userdebug
mka recoveryimage || echo "build step reported an error; checking for ramdisk"
test -s out/target/product/mcv1s/ramdisk-recovery.cpio || { echo "BUILD FAILED: no recovery ramdisk. Send the error lines above."; exit 1; }
test -x out/target/product/mcv1s/recovery/root/sbin/recovery || { echo "BUILD FAILED: recovery program missing."; exit 1; }
cd /kit
python3 pack.py /lineage lineage-recovery-mcv1s-UNTESTED.img
