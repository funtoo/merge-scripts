#!/bin/bash
cd /root/funtoo-overlay
# get latest merge.py and friends
git pull || exit 1
# These updates happen, unconditionally:

# Gentoo updates, into their own tree:
/root/funtoo-overlay/funtoo/scripts/gentoo-staging-merge.py || exit 1

# Funtoo tree regen, staged, with no metadata:
/root/funtoo-overlay/funtoo/scripts/funtoo-staging-merge.py || exit 1

# Now perform automated test, and if it works, regen ports-2012:

ssh root@et.host.funtoo.org /root/metro/scripts/ezbuild.sh funtoo-current-next x86-64bit corei7 freshen <SHA1>

var=wget of build file....
if it's "ok", then:

else:
email, don't regen.
fi


#/root/funtoo-overlay/funtoo/scripts/merge.py testing /var/git/dest-trees/ports-2015-testing || exit 1
if [ "$1" == "12h" ]; then
	/root/funtoo-overlay/funtoo/scripts/merge.py staged /var/work/ports-2012 || exit 1
	/root/funtoo-overlay/funtoo/scripts/gentoo-compare.sh
fi
