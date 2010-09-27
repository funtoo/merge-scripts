#!/bin/bash

eval `keychain --noask --eval id_dsa`  || exit 1

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

dest=/var/git/portage-gentoo
final=/var/git/portage-prod
mini=/var/git/portage-mini-2010

src=`pwd`
desttree="funtoo.org"

die() {
	echo $*
	exit 1
}

[ ! -d $dest ] && die "dest dir $dest does not exist"
( cd $dest; git checkout gentoo.org; ) || die "couldn't checkout gentoo.org"
( cd $dest; git pull; ) || die "couldn't pull in gentoo changes"
rsync -av --delete --exclude /.git --exclude /metadata/cache/** $dest/ $final/ || die "rsync death"

#( cd $final; rm -rf *; git reset --hard ) || die "couldn't reset $final to pristine state"
# Patches:
for pat in `cat funtoo/patches/series | grep -v '^#'`
do
	( cd $final; git apply "$src/funtoo/patches/$pat" ) || die "patch $pat failed"
done
rsync -av "$src"/funtoo/profiles/ $final/profiles/ || die "rsync of whole profile files failed"

# "*-*" will eliminate licenses, eclass, funtoo directories:

for foo in `ls -d *-*/*`
do
	[ -d $final/$foo ] && echo "Replacing upstream ${foo}..." && ( cd $final; [ -e $foo ] && rm -rf $foo; )
	install -d `dirname $final/$foo` || die "install -d fail"
	cp -a $foo $final/$foo || die "cp -a fail"
done

# Misc files:

cp licenses/* $final/licenses/ || die "licenses fail"
cp eclass/* $final/eclass/ || die "eclass fail"

egencache --update --portdir=$final --jobs=14
( cd $final; git add . ) || die "couldn't do git add ."
a=$( cd $final; git status --porcelain )
if [ "$a" != "" ]
then
	#changes
	( cd $final; git commit -a -m "glorious funtoo updates" ) || die "couldn't do glorious updating"
	[ "$1" == "nopush" ] || ( cd $final; git push origin funtoo.org )
else
	echo "No changes detected in repo. Commit skipped."
fi

( cd $mini; git checkout funtoo.org; ) || die "couldn't checkout funtoo.org mini branch"
rsync -av --delete --exclude /.git --exclude ChangeLog $final/ $mini/ || die "mini rsync failure"

# cool cleanups:

( cd $mini; find -iname ChangeLog -exec rm -f {} \; ) || die "ChangeLog zap fail"
( cd $mini; find -iname Manifest -exec sed -n -i -e "/DIST/p" {} \; ) || die "Mini-manifest fail"

( cd $mini; git add . ) || die "couldn't do git add ."
a=$( cd $mini; git status --porcelain )
if [ "$a" != "" ]
then
	#changes
	( cd $mini; git commit -a -m "glorious funtoo updates" ) || die "couldn't do glorious updating"
	[ "$1" == "nopush" ] || ( cd $mini; git push origin funtoo.org )
else
	echo "No changes detected in repo. Commit skipped."
fi


