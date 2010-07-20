#!/bin/bash

die() {
	echo $*
	exit 1
}

cd /root/git/funtoo-overlay || die "couldn't chdir"
./funtoo/scripts/gentoo-update.sh || die "gentoo update failed"
git pull
./funtoo/scripts/funtoo-update.sh || die "funtoo update failed"
