#!/bin/bash
touch /var/tmp/.regen_running
eval `keychain --noask --eval id_dsa`  || exit 1

die() {
	echo $*
	rm -f /var/tmp/.regen_running
	exit 1
}
cd /root/git/funtoo-overlay || die "couldn't chdir"
git pull
./funtoo/scripts/gentoo-update.sh || die "gentoo update failed"
./funtoo/scripts/merge.py /var/git/portage-mini-2011 || die "funtoo update failed"
rm -f /var/tmp/.regen_running
