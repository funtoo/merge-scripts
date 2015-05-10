#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

hour=$(date +%H)
minute=$(date +%M)

if [ "$( echo $hour % 4 | bc)" -eq 0 ] && [ "$minute" -eq 5 ]; then
	# run the merge-gentoo script every 4 hours, on the 5th minute.
	$DIR/merge-gentoo-staging.py
fi
if [ "$( echo $minute % 5 | bc)" -eq 0 ]; then
	# Then, run the merge-funtoo script every 5 minutes."
	$DIR/merge-funtoo.sh
	if [ $? -eq 1 ]; then
		# some kind of error occurred.
		echo "Error! merge-funtoo.sh encountered some problem"
		exit 1
	fi
fi
#5 */4 * * *    /root/funtoo-overlay/funtoo/scripts/merge-gentoo-staging.py
#*/5 * * * *    /root/funtoo-overlay/funtoo/scripts/merge-funtoo.sh
#30 12 * * *    /root/funtoo-overlay/funtoo/scripts/qa-builds.py

