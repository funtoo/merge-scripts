#!/bin/bash

dest=/var/tmp/git/portage-gentoo
src=`pwd`
desttree="funtoo.org-desttree"

die() {
	echo $*
	exit 1
}

[ ! -d $dest ] && die "dest dir $dest does not exist"

( cd $dest; git checkout gentoo.org; ) || die "couldn't checkout gentoo.org"
( cd $dest; git branch -D testmerge; )
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
		if [ -e "$dest/$foo/Manifest" ] 
		then
			(cd $dest/$foo; FEATURES="-mini-manifest" ebuild `ls *.ebuild | tail -n 1` digest;) || die "digest gen failure"
		fi
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

# cool cleanups:

# ( cd $dest; find -iname ChangeLog -exec rm -f {} \; ) || die "ChangeLog zap fail"
# ( cd $dest; find -iname Manifest -exec sed -n -i -e "/DIST/p" {} \; ) || die "Mini-manifest fail"

( cd $dest; git add * ) || die "couldn't add"
( cd $dest; git commit -a -m "merged tree" ) || die "couldn't merge tree"

echo "Creating Portage tarball..."
tar cf /var/tmp/git/curmerge.tar -C $dest --exclude .git . || die "tarball create error"

( cd $dest; git checkout $desttree ) || die "couldn't checkout $desttree destree"
( cd $dest; rm -rf * ) || die "couldn't prep tree"
echo "Extracting Portage tarball..."
( cd $dest; tar xpf /var/tmp/git/curmerge.tar ) || die "couldn't unpack tarball"
( cd $dest; git add . ) || die "couldn't do git add ."
( cd $dest; git commit -a -m "glorious updates" ) || die "couldn't do glorious updating"
