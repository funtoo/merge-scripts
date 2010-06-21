#!/bin/sh
# Written by Douglas Goldstein <cardoe@gentoo.org>
# This code is hereby placed into the public domain
#
# $Id: use_desc_gen.sh,v 1.6 2008/08/23 21:28:28 robbat2 Exp $

usage() {
	prog=$(basename $1)

	echo "${prog} /path/to/portage/tree"
	exit 1;
}

if [ $# -ne 1 ]; then
	usage $0;
fi

if [ "x${1}" = "x-h" -o "x${1}" = "x--help" ]; then
	usage $0;
fi

if [ ! -f "${1}/profiles/use.local.desc" ]; then
	usage $0;
fi

pid=$(echo $$)

# make list of categories that we want to remove from current use.local.desc
#cat "${1}/profiles/use.local.desc" | sed '1,/# The following categories/d;/# End of metadata categories/,$d;s/^../^/' > /tmp/${pid}.grep

# we also want to remove comments and blank lines
#echo "^#" >> /tmp/${pid}.grep
#echo "^$" >> /tmp/${pid}.grep

# make list of categories to process with use_desc_gen (same as above without grep rule)
#cat "${1}/profiles/use.local.desc" | sed '1,/# The following categories/d;/# End of metadata categories/,$d;s/^..//' > /tmp/${pid}.categories

# take comments from existing use.local.desc
grep '^#' "${1}/profiles/use.local.desc" > /tmp/${pid}.use.local.desc
echo "" >> /tmp/${pid}.use.local.desc

# use list from step #1 to filter current use.local.desc and add un-converted categories to new use.local.desc
#grep -v -f /tmp/${pid}.grep "${1}/profiles/use.local.desc" > /tmp/${pid}.new.use

# the secret sauce, append to new use.local.desc
python scripts/use_desc_gen.py --repo_path "${1}" > /tmp/${pid}.new.use

# let's keep it sorted: use major category, minor category, and package name
# as primary, secondary, and tertiary sort keys, respectively
sort -t: -k1,1 -k2 /tmp/${pid}.new.use | sort -s -t/ -k1,1 \
    >> /tmp/${pid}.use.local.desc

# clean up
#rm -rf /tmp/${pid}.categories
#rm -rf /tmp/${pid}.grep
rm -rf /tmp/${pid}.new.use

mv /tmp/${pid}.use.local.desc profiles/use.local.desc
