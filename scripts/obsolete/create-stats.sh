#!/bin/bash

ebuilds=$(ls *-*/* -d)

#declare -a bugs ebuilds cc

#a=0
#for i in ${ebuildsin}; do
#	ebuilds[$a]=${i}
#	a=$[ $a+1 ];
#done
# second loop
#a=0
#for i in ${bugsin}; do
#	bugs[$a]=${i}
#	a=$[ $a+1 ];
#done

for i in $ebuilds; do
	bug=$(grep -oE "[0-9]{2}[0-9]+" $i/ChangeLog | tail -n 1)
	bugz get $bug > /tmp/crst
	cc=$(grep CC /tmp/crst | sed -e "s/CC          : //");
	assignee=$(grep Assignee /tmp/crst | sed -e "s/Assignee    : //");
	echo $i - bug $bug - $assignee - on CC: $cc;
done

