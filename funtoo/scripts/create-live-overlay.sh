#!/bin/bash

# This script uses an existing Gentoo Portage tree and "preps" it so that it
# can be used as the base tree, with this funtoo-overlay git tree configured as
# an overlay on top of it. When configured as your system's portage tree, you
# will have a "live" Funtoo tree where changes in the funtoo-overlay will be
# available to you for testing without any additional steps.

# IMPORTANT: The contents of the existing Gentoo Portage tree *will* be modified.
# ebuilds that exists in both the funtoo and gentoo trees will be *removed*
# from the Gentoo tree.

dest=${portage_gentoo:-/var/tmp/git/portage-gentoo-overlay}

src=$(readlink -f $(dirname $0)/../../)

die() {
	echo $*
	exit 1
}

[ ! -d $dest ] && die "dest dir $dest does not exist"
( cd $dest; git checkout gentoo.org; ) || die "couldn't checkout gentoo.org"
( cd $dest; git pull; ) || die "couldn't pull in gentoo changes"
( cd $dest; git branch -D gentoo.org-overlay-base ) # this can fail if branch doesn't exist and that's ok
( cd $dest; git branch -D gentoo.org-overlay-base.stg ) # this can fail if branch doesn't exist and that's ok
( cd $dest; git checkout -b gentoo.org-overlay-base ) || die "couldn't create new overlay base"

( cd $dest; stg init ) # this can fail and that's ok
( cd $dest; stg pop -a ) 
( cd $dest; stg import --replace -s $src/funtoo/patches/series ) || die "couldn't import patch series"
( cd $dest; stg new removed-ebuilds ) || die "couldn't create new stg patch"

( cd $src && for foo in `ls -d *-*/*`
do
	[ -d $dest/$foo ] && echo "Replacing upstream ${foo}..." && ( cd $dest; [ -e $foo ] && rm -rf $foo; )
	install -d `dirname $dest/$foo` || die "install -d fail"
	cp -a $foo $dest/$foo || die "cp -a fail"
	( cd $dest; git add $foo ) || die "couldn't add new goodies"
done )

( cd $dest; stg refresh ) || die "couldn't refresh funtoo updates"
#( cd $dest; git add sets.conf sets licenses/* eclass/* ) || die "couldn't git add"
#( cd $dest; stg refresh ) || die "couldn't refresh funtoo updates 2"
echo "Done."
