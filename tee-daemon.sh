#!/sbin/sh
# Run by init (service tee_daemon). tee-setup.sh prepares the files first.
export LD_LIBRARY_PATH=/sbin
export MC_AUTH_TOKEN_PATH=/vendor/persist-lg/mcRegistry
exec /sbin/mcDriverDaemon $(cat /tmp/mcv/daemon.args) >/tmp/mcv/daemon.out 2>&1
