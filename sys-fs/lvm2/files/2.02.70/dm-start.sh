# /lib/rcscripts/addons/dm-start.sh:  Setup DM volumes at boot

if grep -q device-mapper /proc/misc; then
	ebegin "Auto-detecting device-mapper volumes"
	/sbin/dmsetup mknodes
else
	ebegin "Kernel does not support device-mapper, skipping"
fi

eend 0

# vim:ts=4
