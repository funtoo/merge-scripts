# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

tmpfs_size="10M"

[ -e /etc/udev/udev.conf ] && . /etc/udev/udev.conf

get_modules_autoload_file() {
	# code copied from /etc/init.d/modules

	# Should not fail if kernel do not have module
	# support compiled in ...
	[ ! -f /proc/modules -o "${RC_SYS}" = "VPS" ] && return 0

	local KV=$(uname -r)
	local KV_MAJOR=${KV%%.*}
	local x=${KV#*.}
	local KV_MINOR=${x%%.*}
	x=${KV#*.*.}
	local KV_MICRO=${x%%-*}

	local auto=""
	if [ -f /etc/modules.autoload -a ! -L /etc/modules.autoload ]; then
		auto=/etc/modules.autoload
	else
		local x= f="/etc/modules.autoload.d/kernel"
		for x in "${KV}" ${KV_MAJOR}.${KV_MINOR}.${KV_MICRO} ${KV_MAJOR}.${KV_MINOR} ; do
			if [ -f "${f}-${x}.${RC_SOFTLEVEL}" ] ; then
				auto="${f}-${x}.${RC_SOFTLEVEL}"
				break
			fi
			if [ "${RC_SOFTLEVEL}" = "${RC_BOOTLEVEL}" -a -f "${f}-${x}.${RC_DEFAULTLEVEL}" ] ; then
				auto="${f}-${x}.${RC_DEFAULTLEVEL}"
				break
			fi
			if [ -f "${f}-${x}" ] ; then
				auto="${f}-${x}"
				break
			fi
		done
	fi
	echo "${auto}"
}

mount_dev_directory() {
	# Setup temporary storage for /dev
	ebegin "Mounting /dev for udev"
	if [ "${RC_USE_FSTAB}" = "yes" ] ; then
		mntcmd=$(get_mount_fstab /dev)
	else
		unset mntcmd
	fi
	if [ -n "${mntcmd}" ] ; then
		try mount -n ${mntcmd}
	else
		mntopts="exec,nosuid,mode=0755,size=${tmpfs_size}"
		if grep -Eq "[[:space:]]+tmpfs$" /proc/filesystems ; then
			mntcmd="tmpfs"
		else
			mntcmd="ramfs"
		fi
		# many video drivers require exec access in /dev #92921
		try mount -n -t "${mntcmd}" -o "${mntopts}" udev /dev
	fi
	eend $?
}

populate_udev() {
	# populate /dev with devices already found by the kernel

	# tell modprobe.sh to be verbose to $CONSOLE

	echo "export CONSOLE=${CONSOLE}" > /dev/.udev_populate
	echo "export TERM=${TERM}" >> /dev/.udev_populate
	echo "export MODULES_AUTOLOAD_FILE=$(get_modules_autoload_file)" >> /dev/.udev_populate

	if get_bootparam "nocoldplug" ; then
		RC_COLDPLUG="no"
		ewarn "Skipping udev coldplug as requested in kernel cmdline"
	fi

	# at this point we are already sure to use kernel 2.6.15 or newer
	ebegin "Populating /dev with existing devices through uevents"
	local opts=
	[ "${RC_COLDPLUG}" != "yes" ] && opts="--attr-match=dev"
	/sbin/udevtrigger ${opts}
	eend $?

	# loop until everything is finished
	# there's gotta be a better way...
	ebegin "Letting udev process events"
	/sbin/udevsettle --timeout=60
	eend $?

	rm -f /dev/.udev_populate
	return 0
}

seed_dev() {
	# Seed /dev with some things that we know we need
	ebegin "Seeding /dev with needed nodes"

	# creating /dev/console and /dev/tty1 to be able to write
	# to $CONSOLE with/without bootsplash before udevd creates it
	[ ! -c /dev/console ] && mknod /dev/console c 5 1
	[ ! -c /dev/tty1 ] && mknod /dev/tty1 c 4 1
	
	# udevd will dup its stdin/stdout/stderr to /dev/null
	# and we do not want a file which gets buffered in ram
	[ ! -c /dev/null ] && mknod /dev/null c 1 3

	# copy over any persistant things
	if [ -d /lib/udev/devices ] ; then
		cp --preserve=all --recursive --update /lib/udev/devices/* /dev 2>/dev/null
	fi

	# Not provided by sysfs but needed
	ln -snf /proc/self/fd /dev/fd
	ln -snf fd/0 /dev/stdin
	ln -snf fd/1 /dev/stdout
	ln -snf fd/2 /dev/stderr
	[ -e /proc/kcore ] && ln -snf /proc/kcore /dev/core

	# Create problematic directories
	mkdir -p /dev/pts /dev/shm
	eend 0
}

unpack_device_tarball() {
	# Actually get udev rolling
	if [ "${RC_DEVICE_TARBALL}" = "yes" ] && \
	    [ -s /lib/udev/state/devices.tar.bz2 ] ; then
		ebegin "Populating /dev with saved device nodes"
		try tar -jxpf /lib/udev/state/devices.tar.bz2 -C /dev
		eend $?
	fi
}

check_persistent_net() {
	# check if there are problems with persistent-net
	local syspath=
	local devs=
	local problem_found=0
	for syspath in /sys/class/net/*_rename*; do
		if [ -d "${syspath}" ]; then
			devs="${devs} ${syspath##*/}"
			problem_found=1
		fi
	done

	[ "${problem_found}" = 0 ] && return 0

	eerror "UDEV: Your system has a problem assigning persistent names"
	eerror "to these network interfaces: ${devs}"

	einfo "Checking persistent-net rules:"
	# the sed-expression lists all duplicate lines
	# from the input, like "uniq -d" does, but uniq
	# is installed into /usr/bin and not available at boot.
	dups=$(
		RULES_FILE='/etc/udev/rules.d/70-persistent-net.rules'
		. /lib/udev/rule_generator.functions
		find_all_rules 'NAME=' '.*'|tr ' ' '\n'|sort|sed '$!N; s/^\(.*\)\n\1$/\1/; t; D'
		)
	if [ -n "${dups}" ]; then
		ewarn "The rules create multiple entries assigning these names:"
		eindent
		ewarn "${dups}"
		eoutdent
	else
		ewarn "Found no duplicate names in persistent-net rules,"
		ewarn "there must be some other problem!"
	fi
	return 1
}

main() {
	if [ $(get_KV) -le $(KV_to_int '2.6.14') ] ; then
		eerror "Your kernel is too old to work with this version of udev."
		eerror "Current udev only supports Linux kernel 2.6.15 and newer."
		return 1
	fi

	mount_dev_directory

	# Create a file so that our rc system knows it's still in sysinit.
	# Existance means init scripts will not directly run.
	# rc will remove the file when done with sysinit.
	touch /dev/.rcsysinit

	# Selinux lovin; /selinux should be mounted by selinux-patched init
	if [ -x /sbin/restorecon -a -c /selinux/null ] ; then
		restorecon /dev > /selinux/null
	fi

	unpack_device_tarball
	seed_dev

	if [ -e /proc/sys/kernel/hotplug ] ; then
		echo "" > /proc/sys/kernel/hotplug
	fi

	ebegin "Starting udevd"
	/sbin/udevd --daemon
	eend $?

	/lib/udev/write_root_link_rule
	populate_udev

	# Only do this for baselayout-1*
	if [ ! -e /lib/librc.so ]; then

		# Create nodes that udev can't
		ebegin "Finalizing udev configuration"
		[ -x /sbin/lvm ] && \
			/sbin/lvm vgscan -P --mknodes --ignorelockingfailure &>/dev/null
		# Running evms_activate on a LiveCD causes lots of headaches
		[ -z "${CDBOOT}" -a -x /sbin/evms_activate ] && \
			/sbin/evms_activate -q &>/dev/null
		eend 0
	fi

	check_persistent_net

	# trigger executing initscript when /etc is writable
	IN_HOTPLUG=1 /etc/init.d/udev-postmount start >/dev/null 2>/dev/null

	# udev started successfully
	return 0
}

main

# vim:ts=4
