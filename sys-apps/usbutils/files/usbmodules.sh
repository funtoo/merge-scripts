#!/bin/sh

usage() {
	cat <<-EOF
	List relevant kernel modules for USB devices currently plugged in.  The
	module list is taken from the modules installed in /lib/modules/<ver>/.

	Usage: usbmodules [options] [kernel version]

	Options:
	  -m, --map <map>   Specify usbmap (default: /lib/modules/<ver>/modules.usbmap)
	  -h, --help        This help screen
	EOF
	if [ -n "$*" ] ; then
		echo
		echo "Error: $*" 1>&2
		exit 1
	else
		exit 0
	fi
}

map=""

while [ -n "$1" ] ; do
	case $1 in
		-m|--map)  map=$2; shift;;
		-h|--help) usage;;
		--)        break;;
		-*)        usage "unknown option '$1'";;
		*)         break;;
	esac
	shift
done

ver=${1:-$(uname -r)}
map=${map:-/lib/modules/${ver}/modules.usbmap}

for dev in $(lsusb | awk '{print $6}') ; do
	[ "${dev}" = "0000:0000" ] && continue

	IFS=:
	set -- ${dev}
	vendor=$1
	product=$2
	unset IFS

	awk \
		-v vendor="0x${vendor}" \
		-v product="0x${product}" \
		'vendor == $3 && product == $4 {print $1}' \
		${map}
done

exit 0
