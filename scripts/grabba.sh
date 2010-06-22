#!/bin/bash

dest=/var/tmp/git/portage-testmerge
src=`pwd`

die() {
	echo $*
	exit 1
}

[ ! -d $dest ] && die "dest dir $dest does not exist"
[ -e funtoo/funtoo-revert ] || die "funtoo-revert missing"
[ -e funtoo/funtoo-misc ] || die "funtoo-misc missing"

for foo in `cat funtoo/funtoo-revert funtoo/funtoo-misc | grep -v '^#'`
do
	( cd $dest; [ -e $foo ] && rm -rf $foo; )
done

# "*-*" will eliminate licenses, eclass, funtoo directories:

for foo in `ls -d *-*/*`
do
	dirn="`dirname $foo`"
	if [ ! -d $dest/$foo ]
	then
		install -d `dirname $dest/$foo` || die "install -d fail"
		cp -a $foo $dest/$foo || die "cp -a fail"
	else
		echo "ERROR Already exists - $foo"
		die "dir exists failure"
	fi
done

# Patches:
for pat in `cat funtoo/patches/series | grep -v '^#'`
do
	( cd $dest; cat "$src/funtoo/patches/$pat" | patch -p1; ) || die "patch $pat failed"
done

# Misc files:

cp -a sets.conf $dest/ || die "sets.conf fail"
cp -a sets $dest/ || die "sets fail"
rsync -a scripts/ $dest/scripts/ || die "rsync scripts fail"
cp licenses/* $dest/licenses/ || die "licenses fail"
cp eclass/* $dest/eclass/ || die "eclass fail"

