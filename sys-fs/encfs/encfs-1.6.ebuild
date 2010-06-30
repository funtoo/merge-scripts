# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/encfs/encfs-1.6.ebuild,v 1.4 2010/06/29 08:54:27 caster Exp $

EAPI=2

inherit multilib versionator

DESCRIPTION="An implementation of encrypted filesystem in user-space using FUSE"
HOMEPAGE="http://www.arg0.net/encfs/"
SRC_URI="http://encfs.googlecode.com/files/${P}-1.tgz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~sparc ~x86"
IUSE=""

RDEPEND=">=dev-libs/boost-1.34
	>=dev-libs/openssl-0.9.7
	>=dev-libs/rlog-1.4
	>=sys-fs/fuse-2.7.0"
DEPEND="${RDEPEND}
	dev-lang/perl
	dev-util/pkgconfig
	sys-apps/attr
	sys-devel/gettext"

src_configure() {
	BOOST_PKG="$(best_version dev-libs/boost)"
	BOOST_VER="$(get_version_component_range 1-2 "${BOOST_PKG/*boost-/}")"
	BOOST_VER="$(replace_all_version_separators _ "${BOOST_VER}")"
	BOOST_INC="/usr/include/boost-${BOOST_VER}"
	BOOST_LIB="/usr/$(get_libdir)/boost-${BOOST_VER}"
	einfo "Building against ${BOOST_PKG}."

	econf \
		--with-boost=${BOOST_INC} \
		--with-boost-libdir=${BOOST_LIB} \
		--disable-dependency-tracking
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog README
	find "${D}" -name '*.la' -delete
}
