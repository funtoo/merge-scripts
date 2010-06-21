# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/profiles/hardened/x86/2.6/profile.bashrc,v 1.1 2009/03/24 17:29:22 gengor Exp $

if [[ "${EBUILD_PHASE}" == "setup" ]]
then
	echo
	ewarn "The hardened/x86/2.6 profile is deprecated.  This profile has been"
	ewarn "pushed down to hardened/x86.  Please update your /etc/make.profile"
	ewarn "symlink to use the hardened/x86 profile.  See: eselect profile list"
	echo
fi
