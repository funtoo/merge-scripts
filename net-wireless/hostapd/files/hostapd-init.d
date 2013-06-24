#!/sbin/runscript
# Distributed under the terms of the GNU General Public License v2

extra_started_commands="reload"

depend() {
	local myneeds=
	for iface in ${INTERFACES}; do
		myneeds="${myneeds} netif.${iface}"
	done

	[ -n "${myneeds}" ] && need ${myneeds}
	use logger
}

checkconfig() {
	local file

	for file in ${CONFIGS}; do
		if [ ! -r "${file}" ]; then
			eerror "hostapd configuration file (${CONFIG}) not found"
			return 1
		fi
	done
}

start() {
	checkconfig || return 1

	ebegin "Starting ${SVCNAME}"
	start-stop-daemon --start --exec /usr/sbin/hostapd \
		-- -B ${OPTIONS} ${CONFIGS}
	eend $?
}

stop() {
	ebegin "Stopping ${SVCNAME}"
	start-stop-daemon --stop --exec /usr/sbin/hostapd
	eend $?
}

reload() {
	checkconfig || return 1

	ebegin "Reloading ${SVCNAME} configuration"
	kill -HUP $(pidof /usr/sbin/hostapd) > /dev/null 2>&1
	eend $?
}
