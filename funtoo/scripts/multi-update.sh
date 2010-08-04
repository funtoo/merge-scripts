#!/bin/bash

die() {
	echo $*
	exit 1
}

cd /root/git/funtoo-overlay || die "couldn't chdir"
git pull
./funtoo/scripts/gentoo-update.sh || die "gentoo update failed"
./funtoo/scripts/funtoo-update.sh || die "funtoo update failed"
