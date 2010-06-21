# /lib/rcscripts/addons/lvm-start.sh
# $Header: /var/cvsroot/gentoo-x86/sys-fs/lvm2/files/lvm2-start.sh-2.02.49-r3,v 1.1 2009/08/07 21:02:28 robbat2 Exp $

config='global { locking_dir = "/dev/.lvm" }'

dm_in_proc() {
	local retval=0
	for x in devices misc ; do
		grep -qs 'device-mapper' /proc/${x}
		retval=$((${retval} + $?))
	done
	return ${retval}
}

# LVM support for /usr, /home, /opt ....
# This should be done *before* checking local
# volumes, or they never get checked.

# NOTE: Add needed modules for LVM or RAID, etc
#       to /etc/modules.autoload if needed
if [ -z "${CDBOOT}" -a -x /sbin/vgscan ] ; then
	if [ -e /proc/modules ] && ! dm_in_proc ; then
		modprobe dm-mod 2>/dev/null
	fi

	if [ -d /proc/lvm ] || dm_in_proc ; then
		ebegin "Setting up the Logical Volume Manager"
		#still echo stderr for debugging
		# Extra PV find pass because some devices might not have been available until very recently
		/sbin/pvscan --config "${config}" >/dev/null
		# Now make the nodes
		/sbin/vgscan --mknodes --config "${config}" >/dev/null
		if [ -x /sbin/vgchange ] && \
		   [ -f /etc/lvmtab -o -d /etc/lvm ]
		then
			/sbin/vgchange --config "${config}" -a y >/dev/null
		fi
		eend $? "Failed to setup the LVM"
	fi
fi

# vim:ts=4
