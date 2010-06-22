#!/bin/bash

dest=/var/tmp/git/portage-gentoo
src=`pwd`

die() {
	echo $*
	exit 1
}

[ ! -d $dest ] && die "dest dir $dest does not exist"

( cd $dest; git branch -D testmerge; )
( cd $dest; git checkout gentoo.org; ) || die "couldn't checkout gentoo.org"
( cd $dest; git checkout -b testmerge; ) || die "couldn't create testmerge"

[ -e funtoo/funtoo-revert ] || die "funtoo-revert missing"
[ -e funtoo/funtoo-misc ] || die "funtoo-misc missing"

# Patches:
for pat in `cat funtoo/patches/series | grep -v '^#'`
do
	( cd $dest; git apply "$src/funtoo/patches/$pat" ) || die "patch $pat failed"
done


for foo in `cat funtoo/funtoo-revert funtoo/funtoo-misc | grep -v '^#'`
do
	( cd $dest; [ -e $foo ] && rm -rf $foo; )
done

# "*-*" will eliminate licenses, eclass, funtoo directories:

for foo in `ls -d *-*/* virtual/*`
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

# Misc files:

cp -a sets.conf $dest/ || die "sets.conf fail"
cp -a sets $dest/ || die "sets fail"
rsync -a scripts/ $dest/scripts/ || die "rsync scripts fail"
cp licenses/* $dest/licenses/ || die "licenses fail"
cp eclass/* $dest/eclass/ || die "eclass fail"

git add . || die "couldn't add"
git commit -a -m "merged tree" || die "couldn't merge tree"

tar cvf /var/tmp/git/curmerge.tar -C $dest --exclude .git
