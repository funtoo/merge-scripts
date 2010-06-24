#!/bin/bash

# This script uses the contents of the funtoo-overlay to generate 
# a merged funtoo+gentoo unified tree, which is then used to update the
# funtoo.org git tree with the latest changes from both funtoo and gentoo.
# These changes are placed in a commit which can then be pushed to
# github so users can "emerge --sync" to grab these changes.

# This script is designed to run from the root of the funtoo-overlay:

# cd /root/git/funtoo-overlay
# scripts/funtoo/grabba.sh

# "dest" points to a git tree that contains a gentoo.org tree that will
# be used to generate the funtoo+gentoo unified tree data. This data is
# then placed in a tarball.

# "final" points to a git tree that contains a funtoo.org tree that will
# receive the new updates. The contents of the working dir will be removed
# with rm -rf, and the tarball will be unpacked, egencache will be run
# and then git add * and git commit will be run to generate an update
# to the funtoo tree. This commit can then be reviewed, and manually
# pushed up to github.com so other users can grab it via emerge --sync.

dest=/var/tmp/git/portage-gentoo
final=/var/tmp/git/portage-prod
src=`pwd`
desttree="funtoo.org"

die() {
	echo $*
	exit 1
}

[ ! -d $dest ] && die "dest dir $dest does not exist"

( cd $dest; git checkout gentoo.org; ) || die "couldn't checkout gentoo.org"
( cd $dest; git pull; ) || die "couldn't pull in gentoo changes"
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

# Misc files:

cp -a sets.conf $dest/ || die "sets.conf fail"
cp -a sets $dest/ || die "sets fail"
cp licenses/* $dest/licenses/ || die "licenses fail"
cp eclass/* $dest/eclass/ || die "eclass fail"

# cool cleanups:

# ( cd $dest; find -iname ChangeLog -exec rm -f {} \; ) || die "ChangeLog zap fail"
# ( cd $dest; find -iname Manifest -exec sed -n -i -e "/DIST/p" {} \; ) || die "Mini-manifest fail"

( cd $dest; git add * ) || die "couldn't add"
( cd $dest; git commit -a -m "merged tree" ) || die "couldn't merge tree"

echo "Creating Portage tarball..."
tar cf /var/tmp/git/curmerge.tar -C $dest --exclude .git . || die "tarball create error"

( cd $final; git checkout $desttree ) || die "couldn't checkout $desttree destree"
( cd $final; rm -rf * ) || die "couldn't prep tree"
echo "Extracting Portage tarball..."
( cd $final; tar xpf /var/tmp/git/curmerge.tar ) || die "couldn't unpack tarball"
egencache --update --portdir=$final --jobs=14
( cd $final; git add . ) || die "couldn't do git add ."
( cd $final; git commit -a -m "glorious funtoo updates" ) || die "couldn't do glorious updating"
