#!/bin/bash
# Distributed under the terms of the GNU General Public License v2

ret=0 opts= gov_opts= sep=
for o in "${@}" ; do
	[ "${o}" = "--" ] && sep=1 && continue
	if [ -n "${sep}" ]; then
		gov_opts="${gov_opts} ${o}"
	else
		opts="${opts} ${o}"
	fi
done

echo "cpufreq-set options: ${opts}"
echo "Governor options: ${gov_opts}"

for c in $(cpufreq-info -o | awk '$1 == "CPU" { print $2 }') ; do
	cpufreq-set -c ${c} ${opts}
	: $(( ret += $? ))
done

 if [ -n "${gov_opts}" ]; then
	c=1
	if cd /sys/devices/system/cpu/cpufreq ; then
		for o in ${gov_opts}; do
			v=${o#*=}
			o=${o%%=*}
			echo ${v} > ${o} || break
		done
		c=0
	fi
	: $(( ret += c ))
fi

exit ${ret}
