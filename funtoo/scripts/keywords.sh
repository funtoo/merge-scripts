#!/bin/bash
inherit() {
	for x in $*
	do
		. eclass/$x.eclass
	done
}

has() {
	echo
}

eerror() {
	echo
}

use() {
	echo
}

die() {
	echo
}

EXPORT_FUNCTIONS() {
	if [ -z "$ECLASS" ]; then
		die "EXPORT_FUNCTIONS without a defined ECLASS"
	fi
	#eval $__export_funcs_var+=\" $*\"
}


a=$( cd $1; . $2; echo $KEYWORDS )
echo $a

