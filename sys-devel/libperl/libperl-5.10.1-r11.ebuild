# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/libperl/libperl-5.10.1.ebuild,v 1.2 2009/09/27 11:00:50 tove Exp $

inherit multilib

DESCRIPTION="Larry Wall's Practical Extraction and Report Language"
SRC_URI=""
HOMEPAGE="http://www.gentoo.org/"

LICENSE="GPL-2"
SLOT="1"
KEYWORDS="amd64 x86"
IUSE=""

PDEPEND=">=dev-lang/perl-5.10.1"

pkg_postinst() {
	if [[ -h ${ROOT}/usr/$(get_libdir )/libperl$(get_libname) && \
		! -e ${ROOT}/usr/$(get_libdir )/libperl$(get_libname) ]] ; then
		einfo "Remove symbolic link: ${ROOT}usr/$(get_libdir)/libperl$(get_libname)"
		rm "${ROOT}"/usr/$(get_libdir )/libperl$(get_libname)
	fi
}
