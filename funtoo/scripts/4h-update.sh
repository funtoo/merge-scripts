#!/bin/bash
cd /root/funtoo-overlay
# get latest merge.py and friends
git pull || exit 1
/root/funtoo-overlay/funtoo/scripts/gentoo-merge.py || exit 1
/root/funtoo-overlay/funtoo/scripts/merge.py testing /var/git/dest-trees/ports-2015-testing || exit 1
if [ "$1" == "12h" ]; then
	/root/funtoo-overlay/funtoo/scripts/merge.py staged /var/work/ports-2012 || exit 1
	/root/funtoo-overlay/funtoo/scripts/gentoo-compare.sh
fi
