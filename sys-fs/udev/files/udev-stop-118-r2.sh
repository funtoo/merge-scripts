# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

/lib/udev/move_tmp_persistent_rules.sh

. /lib/udev/shell-compat.sh

device_tarball=/lib/udev/state/devices.tar.bz2

rc_device_tarball=${rc_device_tarball:-${RC_DEVICE_TARBALL:-NO}}
if [ -e /dev/.devfsd ] || [ ! -e /dev/.udev ] || [ ! -z "${CDBOOT}" ] || \
	! yesno "${rc_device_tarball}" || \
	! touch "${device_tarball}" 2>/dev/null
then
	exit 0
fi

ebegin "Saving device nodes"
# Handle our temp files
save_tmp_base=/tmp/udev.savedevices."$$"
devices_udev="${save_tmp_base}"/devices.udev
devices_real="${save_tmp_base}"/devices.real
devices_totar="${save_tmp_base}"/devices.totar
device_tmp_tarball="${save_tmp_base}"/devices

rm -rf "${save_tmp_base}"
mkdir "${save_tmp_base}"
touch "${devices_udev}" "${devices_real}" \
"${devices_totar}" "${device_tmp_tarball}"

if [ -f "${devices_udev}" -a -f "${devices_real}" -a \
	-f "${devices_totar}" -a -f "${device_tmp_tarball}" ]
then
	cd /dev
	# Find all devices, but ignore .udev directory
	find . -xdev -type b -or -type c -or -type l | \
	cut -d/ -f2- | \
	grep -v ^\\.udev >"${devices_real}"

	# Figure out what udev created
	udevinfo --export-db | sed -ne 's,^[SN]: \(.*\),\1,p' >"${devices_udev}"
	# These ones we also do not want in there
	for x in MAKEDEV core fd initctl pts shm stderr stdin stdout root; do
		echo "${x}" >> "${devices_udev}"
	done
	if [ -d /lib/udev/devices ]; then
		cd /lib/udev/devices
		find . -xdev -type b -or -type c -or -type l | \
		cut -d/ -f2- >> "${devices_udev}"
		cd /dev
	fi

	fgrep -x -v -f "${devices_udev}" "${devices_real}" > "${devices_totar}"

	# Now only tarball those not created by udev if we have any
	if [ -s "${devices_totar}" ]; then
		# we dont want to descend into mounted filesystems (e.g. devpts)
		# looking up username may involve NIS/network
		# and net may be down
		tar --one-file-system --numeric-owner \
			-jcpf "${device_tmp_tarball}" -T "${devices_totar}"
		mv -f "${device_tmp_tarball}" "${device_tarball}"
	else
		rm -f "${device_tarball}"
	fi
	eend 0
else
	eend 1 "Could not create temporary files!"
fi

rm -rf "${save_tmp_base}"
