# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

create_device_tarball() {
	if [ -e /dev/.devfsd ] || [ ! -e /dev/.udev ] || [ ! -z "${CDBOOT}" ] || \
	   [ "${RC_DEVICE_TARBALL}" != "yes" ] || \
	   ! touch /lib/udev/state/devices.tar.bz2 2>/dev/null
	then
		return 0
	fi
		
	ebegin "Saving device nodes"
	# Handle our temp files
	save_tmp_base=/tmp/udev.savedevices."$$"
	devices_udev="${save_tmp_base}"/devices.udev
	devices_real="${save_tmp_base}"/devices.real
	devices_totar="${save_tmp_base}"/devices.totar
	device_tarball="${save_tmp_base}"/devices
	
	rm -rf "${save_tmp_base}"
	mkdir "${save_tmp_base}"
	touch "${devices_udev}" "${devices_real}" \
		"${devices_totar}" "${device_tarball}"
	
	if [ -f ${devices_udev} ] && [ -f ${devices_real} ] && \
	   [ -f ${devices_totar} ] && [ -f ${device_tarball} ] ; then
		cd /dev
		# Find all devices
		find . -xdev -type b -or -type c -or -type l | cut -d/ -f2- > \
			"${devices_real}"
		# Figure out what udev created
		udevinfo=$(udevinfo --export-db)

		# This basically strips 'S:' and 'N:' from the db output, and then
		# print all the nodes/symlinks udev created ...
		echo "${udevinfo}" | gawk '
			/^(N|S):.+/ {
				sub(/^(N|S):/, "")
				split($0, nodes)
				for (x in nodes)
					print nodes[x]
			}' > "${devices_udev}"
		# These ones we also do not want in there
		for x in MAKEDEV core fd initctl pts shm stderr stdin stdout root; do
			echo "${x}" >> "${devices_udev}"
		done
		if [ -d /lib/udev/devices ]; then
			cd /lib/udev/devices
			find . -xdev -type b -or -type c -or -type l | cut -d/ -f2- >> "${devices_udev}"
		fi
		cd /dev
		fgrep -x -v -f "${devices_udev}" < "${devices_real}" | \
		  grep -v ^\\.udev > "${devices_totar}"

		# Now only tarball those not created by udev if we have any
		if [ -s ${devices_totar} ]; then
			# we dont want to descend into mounted filesystems (e.g. devpts)
			# looking up username may involve NIS/network, and net may be down
			tar --one-file-system --numeric-owner -jcpf "${device_tarball}" -T "${devices_totar}"
			mv -f "${device_tarball}" /lib/udev/state/devices.tar.bz2
		else
			rm -f /lib/udev/state/devices.tar.bz2
		fi
		eend 0
	else
		eend 1 "Could not create temporary files!"
	fi

	rm -rf "${save_tmp_base}"
}

main() {
	/lib/udev/move_tmp_persistent_rules.sh
	create_device_tarball
}

main


# vim:ts=4
