#!/bin/bash
inherit() {
	echo
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
	echo
}


a=$( cd $1; . $2  >/dev/null 2>&1; echo "$KEYWORDS" )
echo "$a"
