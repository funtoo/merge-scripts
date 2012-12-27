#!/sbin/runscript
# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# Configuration for /etc/init.d/squeezelite

# IP address of Logitech Media Server; leave this blank to try to
# locate the server via auto-discovery.
SL_SERVERIP=""

# User that Squeezelite should run as. The dedicated 'squeezelite'
# user is preferred to avoid running with high privilege. This user
# should be a member of the 'audio' group to allow access to the audio
# hardware. Running as the 'root' user allows the sound output thread
# to run at a very high priority -- this can help avoid gaps in
# playback, but could be a potential security problem if there are
# exploitable vulnerabilities in Squeezelite.
SL_USER=squeezelite

# Any other switches to pass to Squeezelite. See 'squeezelite -h' for
# a description of all possible switches.
SL_OPTS=""
