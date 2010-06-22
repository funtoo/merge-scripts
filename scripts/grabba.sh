#!/bin/bash

dest=/var/tmp/git/portage-testmerge

for foo in `cat profiles/funtoo-revert profiles/funtoo-misc | grep -v '^#'`
do
	( cd $dest; [ -e $foo ] && git rm -rf $foo; )
done

for foo in `ls -d */*`
do
	[ "`dirname $foo`" = "profiles" ] && continue
	[ "`dirname $foo`" = "licenses" ] && continue
	if [ ! -d $dest/$foo ]
	then
		install -d `dirname $dest/$foo`
		cp -a $foo $dest/$foo
	else
		echo "ERROR Already exists - $foo"
	fi
done

rm -rf $dest/profiles
cp -a profiles $dest/
rsync -a profiles.new/ $dest/profiles/
rsync -a scripts/ $dest/scripts/
cp -a sets.conf $dest/
cp licenses/* $dest/licenses/
