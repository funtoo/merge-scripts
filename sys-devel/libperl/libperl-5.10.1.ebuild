# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/libperl/libperl-5.10.1.ebuild,v 1.12 2010/03/14 15:50:19 aballier Exp $

inherit multilib

DESCRIPTION="Larry Wall's Practical Extraction and Report Language"
SRC_URI=""
HOMEPAGE="http://www.gentoo.org/"

LICENSE="|| ( Artistic GPL-1 GPL-2 GPL-3 )"
SLOT="1"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"
IUSE=""

PDEPEND=">=dev-lang/perl-5.10.1"

pkg_postinst() {
	if [[ $(readlink "${ROOT}/usr/$(get_libdir )/libperl$(get_libname)" ) == libperl$(get_libname).1 ]] ; then
		einfo "Removing stale symbolic link: ${ROOT}usr/$(get_libdir)/libperl$(get_libname)"
		rm "${ROOT}"/usr/$(get_libdir )/libperl$(get_libname)
	fi
}
