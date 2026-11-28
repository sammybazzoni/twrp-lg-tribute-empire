#!/sbin/sh
# TWRP startup (LM-X220PM, mcv1s): get the phone's Trustonic keymaster ready
# before TWRP starts, so that TWRP can unlock /data by itself.
# vendor, system and persist_lg are mounted read-only and the files are copied
# into RAM. init waits for this script, so every wait in it has a limit.
# Log: /tmp/tee-setup.log

WORK=/tmp/mcv
LOG=/tmp/tee-setup.log
PARTS=/dev/block/platform/mtk-msdc.0/11230000.msdc0/by-name
HALS="/vendor/lib/hw/keystore.mcv1s.so /vendor/lib/hw/keystore.mt6750.so /vendor/lib/hw/libMcTeeKeymaster.so"

say() { echo "$*" >>$LOG; }
cleanup() {
    for m in $WORK/vendor $WORK/persist $WORK/system; do
        grep -q " $m " /proc/mounts && umount $m
    done
}
# On failure, take the keymaster library away again: TWRP then starts exactly as
# it did without this script.
die() {
    say "STOPPED: $*"
    rm -f $HALS
    setprop ctl.stop tee_daemon
    cleanup
    exit 1
}
ro_mount() {   # partition, directory.  noload: do not replay the journal
    mkdir -p "$2"
    grep -q " $2 " /proc/mounts && return 0
    mount -t ext4 -o ro,noload "$PARTS/$1" "$2" 2>>$LOG
}
wait_for() {   # test flag, path, seconds
    n=0
    while ! test "$1" "$2"; do
        [ $n -ge "$3" ] && return 1
        sleep 1
        n=$((n + 1))
    done
}

: > $LOG
mkdir -p $WORK

# Time limit for the whole script, so that TWRP always gets to start.
MAIN=$$
( sleep ${TEE_LIMIT:-45}; echo "STOPPED: time limit reached" >>$LOG; rm -f $HALS; setprop ctl.stop tee_daemon; kill -9 $MAIN ) >/dev/null 2>&1 &
WATCHDOG=$!
trap 'kill $WATCHDOG 2>/dev/null' EXIT

say "== automatic unlock setup"
[ "$(getprop ro.hardware)" = mcv1s ] || die "this is not the mcv1s phone"
wait_for -e $PARTS/vendor 5 || die "partition names are not ready"
wait_for -e /dev/mobicore 5 || die "/dev/mobicore is missing"

ro_mount vendor $WORK/vendor || die "could not mount vendor read-only"
V=$WORK/vendor
DAEMON=$V/bin/mcDriverDaemon
HAL=$V/lib/hw/libMcTeeKeymaster.so
CLIENT=$(find $V -name libMcClient.so -path '*lib*' ! -path '*lib64*' | head -n 1)
RC=$(grep -rl 'mcDriverDaemon' $V/etc/init 2>/dev/null | head -n 1)
[ -f $DAEMON ] || die "mcDriverDaemon not found"
[ -f $HAL ] || die "keymaster library not found"
[ -n "$CLIENT" ] || die "libMcClient.so not found"
ls $V/app/mcRegistry/*.drbin >/dev/null 2>&1 || die "Trustonic registry not found"

mkdir -p /vendor/lib/hw /vendor/app/mcRegistry /data/misc/mcRegistry
for f in $HALS; do
    cp $HAL $f || die "copy failed"
done
cp -r $V/app/mcRegistry/. /vendor/app/mcRegistry/ || die "copy failed"
# Never overwrite a library that TWRP already has.
[ -e /sbin/libMcClient.so ] || cp "$CLIENT" /sbin/libMcClient.so || die "copy failed"
cp $DAEMON /sbin/mcDriverDaemon && chmod 0755 /sbin/mcDriverDaemon || die "copy failed"
say "copied keymaster library, client library, daemon and registry"

# Authentication token folder (device secret: copied to RAM only, never printed).
TOKEN=/vendor/persist-lg/mcRegistry
mkdir -p $TOKEN
SRC=""
if [ -d $V/persist-lg/mcRegistry ] && [ ! -L $V/persist-lg ]; then
    SRC=$V/persist-lg/mcRegistry
elif ro_mount persist_lg $WORK/persist; then
    [ -d $WORK/persist/mcRegistry ] && SRC=$WORK/persist/mcRegistry
fi
if [ -n "$SRC" ]; then
    cp -r $SRC/. $TOKEN/
    say "token folder: $(ls -A $TOKEN | wc -l) file(s)"
else
    say "token folder: not found (continuing without it)"
fi

# Android version values the keymaster library reads.
ro_mount system $WORK/system || die "could not mount system read-only"
for key in ro.build.version.release ro.build.version.security_patch; do
    want=$(sed -n "s/^$key=//p" $WORK/system/build.prop | head -n 1)
    [ -n "$want" ] || die "$key is not in the phone's build.prop"
    [ -n "$(getprop $key)" ] || setprop $key "$want"
    wait_for_value=0
    while [ "$(getprop $key)" != "$want" ] && [ $wait_for_value -lt 3 ]; do
        sleep 1
        wait_for_value=$((wait_for_value + 1))
    done
    say "$key: phone=$want twrp=$(getprop $key)"
    [ "$(getprop $key)" = "$want" ] || die "$key does not match the phone's Android"
done

# Use the same driver list as the phone's own service file.
ARGS=""
if [ -n "$RC" ]; then
    LINE=$(sed -e ':a' -e '/\\$/{N;s/\\\n/ /;ba' -e '}' "$RC" | grep '^service .*mcDriverDaemon' | head -n 1)
    for word in $LINE; do
        case $word in
            *.drbin) [ -f "/vendor/app/mcRegistry/${word##*/}" ] && ARGS="$ARGS -r /vendor/app/mcRegistry/${word##*/}" ;;
        esac
    done
fi
if [ -z "$ARGS" ]; then
    for f in /vendor/app/mcRegistry/*.drbin; do ARGS="$ARGS -r $f"; done
fi
echo "$ARGS" > $WORK/daemon.args
cleanup

chmod 0600 /dev/mobicore
say "starting daemon with $(echo $ARGS | grep -o drbin | wc -l) drivers"
# init runs the daemon as a service, so it keeps running after this script ends.
setprop ctl.start tee_daemon
# The kernel creates /dev/mobicore-user once the daemon has started Trustonic.
wait_for -e /dev/mobicore-user 20 || die "Trustonic did not create /dev/mobicore-user"
sleep 2
pidof mcDriverDaemon >/dev/null 2>&1 || die "the Trustonic daemon did not stay running"
chmod 0666 /dev/mobicore-user
[ -e /dev/t-base-tui ] && chmod 0666 /dev/t-base-tui
say "READY: TWRP can now use the keymaster"
