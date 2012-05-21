#!/bin/sh

# Do not continue for non-modular kernel - Bug #168322
[ ! -f /proc/modules ] && exit 0

if [ -e /dev/.udev_populate ]; then
	# Enable verbose while called from udev-addon-start
	. /dev/.udev_populate

	if [ -c "${CONSOLE}" ]; then
		# redirect stdin/out/err
		exec <${CONSOLE} >${CONSOLE} 2>/${CONSOLE}
	fi
fi

# set default if not present in udev.conf
implicitly_blacklist_modules_autoload="yes"
MODPROBE=/sbin/modprobe

. /etc/init.d/functions.sh
[ -e /etc/udev/udev.conf ] && . /etc/udev/udev.conf


# Create a lock file for the current module.
lock_modprobe() {
	[ -e /dev/.udev/ ] || return 0

	MODPROBE_LOCK="/dev/.udev/.lock-modprobe-${MODNAME}"

	retry=20
	while ! mkdir "$MODPROBE_LOCK" 2> /dev/null; do
		if [ $retry -eq 0 ]; then
			 ewarn "Could not lock modprobe ${MODNAME}!"
			 return 1
		fi
		sleep 1
		retry=$(($retry - 1))
	done
	return 0
}

unlock_modprobe() {
	[ "$MODPROBE_LOCK" ] || return 0
	rmdir "$MODPROBE_LOCK" || true
	MODPROBE_LOCK=""
}

load_module() {
	# Get normalized names only with _
	local MODLIST=$("${MODPROBE}" -q -i --show-depends "${@}" 2>/dev/null \
		| sed -e "s#^insmod /lib.*/\(.*\)\.ko.*#\1#g" -e 's|-|_|g')

	# exit if you have no modules to load
	[ -z "${MODLIST}" ] && return 0
	local m
	for m in ${MODLIST}; do
		MODNAME=$m
	done

	lock_modprobe

	if [ -d /sys/module/"${MODNAME}" ]; then
		# already loaded
		unlock_modprobe
		return 0
	fi

	# build regex to match module name written with either - or _
	MOD_REGEX="$(echo "${MODNAME}"|sed -e 's#_#[-_]#g')"

	# check for blacklisting
	if [ -f /etc/modprobe.conf ]; then
		if grep -q '^blacklist.*[[:space:]]'"${MOD_REGEX}"'\([[:space:]]\|$\)' /etc/modprobe.conf; then
			# module blacklisted
			unlock_modprobe
			return 0
		fi
	fi

	if [ "$implicitly_blacklist_modules_autoload" = "yes" -a -f "${MODULES_AUTOLOAD_FILE}" ]; then
		if grep -q "^${MOD_REGEX}"'\([[:space:]]\|$\)' "${MODULES_AUTOLOAD_FILE}"; then
			# module implictly blacklisted
			# as present in modules.autoload, Bug 184833
			unlock_modprobe
			return 0
		fi
	fi

	# now do real loading
	einfo "  udev loading module ${MODNAME}"
	"${MODPROBE}" -q "${@}" >/dev/null 2>/dev/null
	unlock_modprobe
}

while [ -n "${1}" ]; do
	case "${1}" in
	--all|-a) ;;
	*)	load_module "${1}" ;;
	esac
	shift
done

