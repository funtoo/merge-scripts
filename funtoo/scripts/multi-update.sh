#!/bin/bash

eval `keychain --noask --eval id_dsa`  || exit 1

die() {
	echo $*
	exit 1
}

cd /root/git/funtoo-overlay || die "couldn't chdir"
git pull
./funtoo/scripts/gentoo-update.sh || die "gentoo update failed"
./funtoo/scripts/funtoo-update.sh || die "funtoo update failed"
