# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit autotools eutils flag-o-matic multilib-minimal

DESCRIPTION="An implementation of the IDNA2008 specifications (RFCs 5890, 5891, 5892, 5893)"
HOMEPAGE="https://www.gnu.org/software/libidn/#libidn2 https://gitlab.com/jas/libidn2"
SRC_URI="
	mirror://gnu-alpha/libidn/${P}.tar.gz
"

LICENSE="GPL-2+ LGPL-3+"
SLOT="0"
KEYWORDS="*"
IUSE="static-libs"

RDEPEND="
	dev-libs/libunistring[${MULTILIB_USEDEP}]
"
DEPEND="${RDEPEND}
	dev-lang/perl
	dev-util/gtk-doc
	sys-apps/help2man"

PATCHES=(
	"${FILESDIR}"/${PN}-0.12-Werror.patch
	"${FILESDIR}"/${PN}-0.12-examples.patch
	"${FILESDIR}"/${PN}-0.16-gengetopt.patch
	"${FILESDIR}"/${PN}-0.16-cross.patch
	"${FILESDIR}"/${PN}-pkgconfig.diff
)

src_prepare() {
	default

	if [[ ${CHOST} == *-darwin* || ${CHOST} == *-solaris* ]] ; then
		# crude hack, fixed properly for next release, no error.h is present
		sed -i -e '/#include "error\.h"/d' src/idn2.c || die
		append-cppflags -D'error\(E,...\)=exit\(E\)'
	fi

	eautoreconf

	multilib_copy_sources
}

multilib_src_configure() {
	econf \
		$(use_enable static-libs static)
}

multilib_src_install() {
	default
	prune_libtool_files
}
