#!/bin/bash

dest=/var/tmp/git/portage-testmerge

for foo in `cat profiles/funtoo-revert profiles/funtoo-misc | grep -v '^#'`
do
	( cd $dest; [ -e $foo ] && git rm -rf $foo; )
done

for foo in `ls -d */*`
do
	[ "`dirname $foo`" = "profiles" ] && continue
	if [ ! -d $dest/$foo ]
	then
		install -d `dirname $dest/$foo`
		cp -a $foo $dest/$foo
	else
		echo "ERROR Already exists - $foo"
	fi
done

cp -a profiles/updates/* $dest/profiles/updates

rm -rf $dest/profiles/funtoo*
cp -a profiles/funtoo* $dest/profiles
rsync -a scripts/ $dest/scripts/
