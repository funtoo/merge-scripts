#!/bin/sh
# Distributed under the terms of the GNU General Public License v2

. /etc/init.d/functions.sh

# store persistent-rules that got created while booting
# when / was still read-only
store_persistent_rules() {
	local file dest
	local ruledir="$(udevadm info --run)"
	[ ! -d "$ruledir" ] && return 0
	for file in $ruledir/tmp-rules--*; do
		dest=${file##*tmp-rules--}
		[ "$dest" = '*' ] && break
		type=${dest##70-persistent-}
		type=${type%%.rules}
		ebegin "Saving udev persistent ${type} rules to /etc/udev/rules.d"
		cat "$file" >> /etc/udev/rules.d/"$dest" && rm -f "$file"
		eend $? "Failed moving persistent rules!"
	done
}

store_persistent_rules

# vim:ts=4
