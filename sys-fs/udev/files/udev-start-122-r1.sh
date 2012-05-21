# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

[ -e /etc/udev/udev.conf ] && . /etc/udev/udev.conf
. /lib/udev/shell-compat.sh

rc_coldplug=${rc_coldplug:-${RC_COLDPLUG:-YES}}
rc_device_tarball=${rc_device_tarball:-${RC_DEVICE_TARBALL:-NO}}

cleanup()
{
	# fail more gracely and not leave udevd running
	start-stop-daemon --stop --exec /sbin/udevd
	exit 1
}

# FIXME
# Instead of this script testing kernel version, udev itself should
# Maybe something like udevd --test || exit $?
check_kernel()
{
	if [ $(get_KV) -lt $(KV_to_int '2.6.15') ]; then
		eerror "Your kernel is too old to work with this version of udev."
		eerror "Current udev only supports Linux kernel 2.6.15 and newer."
		return 1
	fi
	if [ $(get_KV) -lt $(KV_to_int '2.6.18') ]; then
		ewarn "You need at least Linux kernel 2.6.18 for reliable operation of udev."
	fi
	return 0
}


mount_dev_directory()
{
	# No options are processed here as they should all be in /etc/fstab
	ebegin "Mounting /dev"
	if fstabinfo --quiet /dev; then
		mount -n /dev
	else
		# Some devices require exec, Bug #92921
		mount -n -t tmpfs -o "exec,nosuid,mode=0755,size=10M" udev /dev
	fi
	eend $?
}

unpack_device_tarball()
{
	local device_tarball=/lib/udev/state/devices.tar.bz2
	if yesno "${rc_device_tarball}" && \
		[ -s "${device_tarball}" ]
	then
		ebegin "Populating /dev with saved device nodes"
		tar -jxpf "${device_tarball}" -C /dev
		eend $?
	fi
}

seed_dev()
{
	# Seed /dev with some things that we know we need

	# creating /dev/console and /dev/tty1 to be able to write
	# to $CONSOLE with/without bootsplash before udevd creates it
	[ -c /dev/console ] || mknod /dev/console c 5 1
	[ -c /dev/tty1 ] || mknod /dev/tty1 c 4 1

	# udevd will dup its stdin/stdout/stderr to /dev/null
	# and we do not want a file which gets buffered in ram
	[ -c /dev/null ] || mknod /dev/null c 1 3

	# copy over any persistant things
	if [ -d /lib/udev/devices ]; then
		cp -RPp /lib/udev/devices/* /dev 2>/dev/null
	fi

	# Not provided by sysfs but needed
	ln -snf /proc/self/fd /dev/fd
	ln -snf fd/0 /dev/stdin
	ln -snf fd/1 /dev/stdout
	ln -snf fd/2 /dev/stderr
	[ -e /proc/kcore ] && ln -snf /proc/kcore /dev/core

	# Create problematic directories
	mkdir -p /dev/pts /dev/shm
	return 0
}

disable_hotplug_agent()
{
	if [ -e /proc/sys/kernel/hotplug ]; then
		echo "" >/proc/sys/kernel/hotplug
	fi
}

root_link()
{
	/lib/udev/write_root_link_rule
}

start_udevd()
{
	# load unix domain sockets if built as module, Bug #221253
	if [ -e /proc/modules ] ; then
		modprobe -q unix
	fi
	ebegin "Starting udevd"
	start-stop-daemon --start --exec /sbin/udevd -- --daemon
	eend $?
}

# populate /dev with devices already found by the kernel
populate_dev()
{
	if get_bootparam "nocoldplug" ; then
		rc_coldplug="NO"
		ewarn "Skipping udev coldplug as requested in kernel cmdline"
	fi

	ebegin "Populating /dev with existing devices through uevents"
	if yesno "${rc_coldplug}"; then
		udevadm trigger
	else
		# Do not run any init-scripts, Bug #206518
		udevadm control --env do_not_run_plug_service=1

		# only create device nodes
		udevadm trigger --attr-match=dev

		# run persistent-net stuff, bug 191466
		udevadm trigger --subsystem-match=net
	fi
	eend $?

	ebegin "Waiting for uevents to be processed"
	udevadm settle --timeout=60
	eend $?

	udevadm control --env do_not_run_plug_service=
	return 0
}

compat_volume_nodes()
{
	# Only do this for baselayout-1*
	if [ ! -e /lib/librc.so ]; then

		# Create nodes that udev can't
		[ -x /sbin/lvm ] && \
			/sbin/lvm vgscan -P --mknodes --ignorelockingfailure &>/dev/null
		# Running evms_activate on a LiveCD causes lots of headaches
		[ -z "${CDBOOT}" -a -x /sbin/evms_activate ] && \
			/sbin/evms_activate -q &>/dev/null
	fi
}

check_persistent_net()
{
	# check if there are problems with persistent-net
	local syspath= devs= problem=false
	for syspath in /sys/class/net/*_rename*; do
		if [ -d "${syspath}" ]; then
			devs="${devs} ${syspath##*/}"
			problem=true
		fi
	done

	${problem} || return 0

	eerror "UDEV: Your system has a problem assigning persistent names"
	eerror "to these network interfaces: ${devs}"

	einfo "Checking persistent-net rules:"
	# the sed-expression lists all duplicate lines
	# from the input, like "uniq -d" does, but uniq
	# is installed into /usr/bin and not available at boot.
	dups=$(
	RULES_FILE='/etc/udev/rules.d/70-persistent-net.rules'
	. /lib/udev/rule_generator.functions
	find_all_rules 'NAME=' '.*' | \
	tr ' ' '\n' | \
	sort | \
	sed '$!N; s/^\(.*\)\n\1$/\1/; t; D'
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

check_udev_works()
{
	# should exist on every system, else udev failed
	if [ ! -e /dev/zero ]; then
		eerror "Assuming udev failed somewhere, as /dev/zero does not exist."
		return 1
	fi
	return 0
}



check_kernel || cleanup
mount_dev_directory || cleanup

# Create a file so that our rc system knows it's still in sysinit.
# Existance means init scripts will not directly run.
# rc will remove the file when done with sysinit.
touch /dev/.rcsysinit

# Selinux lovin; /selinux should be mounted by selinux-patched init
if [ -x /sbin/restorecon -a -c /selinux/null ]; then
	restorecon /dev > /selinux/null
fi

unpack_device_tarball
seed_dev
root_link
disable_hotplug_agent

start_udevd || cleanup
populate_dev || cleanup

compat_volume_nodes
check_persistent_net

# trigger executing initscript when /etc is writable
IN_HOTPLUG=1 /etc/init.d/udev-postmount start >/dev/null 2>&1

check_udev_works || cleanup

# udev started successfully
exit 0
