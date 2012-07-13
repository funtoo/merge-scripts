# /lib/rcscripts/addons/lvm-stop.sh
# $Header: /var/cvsroot/gentoo-x86/sys-fs/lvm2/files/lvm2-stop.sh-2.02.67-r1,v 1.1 2010/06/09 22:41:45 robbat2 Exp $

config='global { locking_dir = "/dev/.lvm" }'

# Stop LVM2
if [ -x /sbin/vgs ] && \
   [ -x /sbin/vgchange ] && \
   [ -x /sbin/lvchange ] && \
   [ -f /etc/lvmtab -o -d /etc/lvm ] && \
   [ -d /proc/lvm  -o "`grep device-mapper /proc/misc 2>/dev/null`" ]
then
	einfo "Shutting down the Logical Volume Manager"

        VGS=$(/sbin/vgs --config "${config}" -o vg_name --noheadings --nosuffix 2> /dev/null)

        if [ "$VGS" ]
        then
            ebegin "  Shutting Down logical volumes "
            /sbin/lvchange --config "${config}" --sysinit -a ln ${VGS}
            eend $?

            ebegin "  Shutting Down volume groups "
            /sbin/vgchange --config "${config}" --sysinit -a ln
            eend $?
        fi

	einfo "Finished Shutting down the Logical Volume Manager"
fi

# vim:ts=4
