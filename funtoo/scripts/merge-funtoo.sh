#!/bin/bash
cd /root/funtoo-overlay
# get latest merge.py and friends
git pull || exit 1
/root/funtoo-overlay/funtoo/scripts/merge-funtoo-staging.py
ecode=$?
if [ $ecode -eq 2 ]; then
	# no new updates...
	exit 2
elif [ $ecode -gt 0 ]; then
	# some kind of error
	exit 1	
fi
echo "Starting merge-funtoo-production.py..."
/root/funtoo-overlay/funtoo/scripts/merge-funtoo-production.py
ecode=$?
echo "merge-funtoo-production exit code: $ecode"
if [ $ecode -eq 0 ]; then 
	# update comparison JSON
	/root/funtoo-overlay/funtoo/scripts/gentoo-compare-json.py /var/git/dest-trees/ports-2012 /var/git/source-trees/gentoo-staging/
	exit 0
else
	exit 1
fi
