# /lib/rcscripts/addons/lvm-stop.sh
# From Gentoo bug #319017 

config='global { locking_dir = "/dev/.lvm" }'

# Stop LVM2
if [ -x /sbin/vgs ] && \
   [ -x /sbin/vgchange ] && \
   [ -x /sbin/lvchange ] && \
   [ -f /etc/lvmtab -o -d /etc/lvm ] && \
   [ -d /proc/lvm  -o "`grep device-mapper /proc/misc 2>/dev/null`" ]
then
	einfo "Shutting down the Logical Volume Manager"

        VGS=$(/sbin/vgs -o vg_name --noheadings --nosuffix 2> /dev/null)

        if [ "$VGS" ]
        then
            ebegin "  Shutting Down logical volumes "
            /sbin/lvchange -aln ${VGS}
            eend $?

            ebegin "  Shutting Down volume groups "
            /sbin/vgchange -aln
            eend $?
        fi

	einfo "Finished Shutting down the Logical Volume Manager"
fi

# vim:ts=4
