# /lib/rcscripts/addons/dm-start.sh:  Setup DM volumes at boot
# $Header: /var/cvsroot/gentoo-x86/sys-fs/lvm2/files/dm-start.sh,v 1.1 2009/04/09 23:00:10 caleb Exp $

# char **get_new_dm_volumes(void)
#
#   Return dmsetup commands to setup volumes
get_new_dm_volumes() {
	local volume params

	# Filter comments and blank lines
	grep -v -e '^[[:space:]]*\(#\|$\)' /etc/dmtab | \
	while read volume params ; do
		# If it exists, skip it
		dmvolume_exists "${volume%:}" && continue
		# Assemble the command to run to create volume
		echo "echo ${params} | /sbin/dmsetup create ${volume%:}"
	done

	return 0
}

# int dmvolume_exists(volume)
#
#   Return true if volume exists in DM table
dmvolume_exists() {
	local x line volume=$1

	[ -z "${volume}" ] && return 1

	/sbin/dmsetup ls 2>/dev/null | \
	while read line ; do
		for x in ${line} ; do
			# the following conditonal return only breaks out
			# of the while loop, as it is running in a pipe.
			[ "${x}" = "${volume}" ] && return 1
			# We only want to check the volume name
			break
		done
	done

	# if 1 was returned from the above loop, then indicate that
	# volume exists
	[ $? = 1 ] && return 0

	# otherwise the loop exited normally and the volume does not
	# exist
	return 1
}

# int is_empty_dm_volume(volume)
#
#   Return true if the volume exists in DM table, but is empty/non-valid
is_empty_dm_volume() {
	local table volume=$1

	set -- $(/sbin/dmsetup table 2>/dev/null | grep -e "^${volume}:")
	[ "${volume}" = "$1" -a -z "$2" ]
}

local x volume

if [ -x /sbin/dmsetup -a -c /dev/mapper/control -a -f /etc/dmtab ] ; then
	[ -n "$(get_new_dm_volumes)" ] && \
		einfo " Setting up device-mapper volumes:"

	get_new_dm_volumes | \
	while read x ; do
		[ -n "${x}" ] || continue

		volume="${x##* }"

		ebegin "  Creating volume: ${volume}"
		if ! eval "${x}" >/dev/null 2>/dev/null ; then
			eend 1 "  Error creating volume: ${volume}"
			# dmsetup still adds an empty volume in some cases,
			#  so lets remove it
			is_empty_dm_volume "${volume}" && \
				/sbin/dmsetup remove "${volume}" 2>/dev/null
		else
			eend 0
		fi
	done
fi


# vim:ts=4
