#!/sbin/runscript
# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# These fit the Logitech Media Server ebuild and so shouldn't need to be changed;
# user-servicable parts go in /etc/conf.d/logitechmediaserver.
pidfile=/var/run/logitechmediaserver/logitechmediaserver.pid
logdir=/var/log/logitechmediaserver
varlibdir=/var/lib/logitechmediaserver
cachedir=${varlibdir}/cache
prefsdir=/etc/logitechmediaserver/prefs
prefsfile=/etc/logitechmediaserver/logitechmediaserver.prefs
scuser=logitechmediaserver
scname=logitechmediaserver

depend() {
	need net
	use mysql
}

start() {
	ebegin "Starting Logitech Media Server"

	cd /
	start-stop-daemon \
		--start --exec /usr/sbin/${scname} \
		--pidfile ${pidfile} \
		--user ${scuser} \
		--background \
		-- \
		--quiet \
		--pidfile=${pidfile} \
		--cachedir=${cachedir} \
		--prefsfile=${prefsfile} \
		--prefsdir=${prefsdir} \
		--logdir=${logdir} \
		--audiodir=${LMS_MUSIC_DIR} \
		--playlistdir=${LMS_PLAYLISTS_DIR} \
		${LMS_OPTS}

	eend $? "Failed to start Logitech Media Server"
}

stop() {
	ebegin "Stopping Logitech Media Server"
	start-stop-daemon --retry 10 --stop --pidfile ${pidfile}
	eend $? "Failed to stop Logitech Media Server"
}
