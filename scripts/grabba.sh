#!/bin/bash

dest=/usr/portage-funtoo-packages

for foo in `cat profiles/funtoo-revert | grep -v '#'` 
do
	echo $foo	
	targ=$dest/$foo
	install -d `dirname $targ`
	cp -a $foo $targ
done
