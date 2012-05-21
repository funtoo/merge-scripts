#!/bin/sh
#
# net.sh: udev external RUN script
#
# Copyright 2007 Roy Marples <uberlord@gentoo.org>
# Distributed under the terms of the GNU General Public License v2

IFACE=$1
ACTION=$2

SCRIPT=/etc/init.d/net.$IFACE

# ignore interfaces that are registered after being "up" (?)
case ${IFACE} in
    ppp*|ippp*|isdn*|plip*|lo*|irda*|dummy*|ipsec*|tun*|tap*)
    	exit 0 ;;
esac

if [ ! -x "${SCRIPT}" ] ; then
    logger -t udev-net.sh "${SCRIPT}: does not exist or is not executable"
    exit 1
fi

# If we're stopping then sleep for a bit in-case a daemon is monitoring
# the interface. This to try and ensure we stop after they do.
[ "${ACTION}" == "stop" ] && sleep 2

IN_HOTPLUG=1 "${SCRIPT}" --quiet "${ACTION}"
