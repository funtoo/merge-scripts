# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/encfs/encfs-1.5.ebuild,v 1.6 2009/08/07 10:45:25 ssuominen Exp $

WANT_AUTOMAKE="1.10"

inherit eutils flag-o-matic autotools

MY_P="${P}-2"

DESCRIPTION="Encrypted Filesystem module for Linux"
SRC_URI="http://encfs.googlecode.com/files/${MY_P}.tgz"
HOMEPAGE="http://www.arg0.net/encfs"
LICENSE="GPL-2"
KEYWORDS="amd64 sparc x86"
SLOT="0"
IUSE="nls"

DEPEND=">=dev-libs/openssl-0.9.7
	>=sys-fs/fuse-2.6
	>=dev-libs/rlog-1.3.6
	>=dev-libs/boost-1.34
	nls? ( >=sys-devel/gettext-0.14.1 )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	# bug 245782 - sys-fs/encfs-1.5 fails to build with --as-needed
	epatch "${FILESDIR}"/${P}-boost-system-and-as-needed.patch
	epatch "${FILESDIR}"/${P}-glibc-2.10.patch
	eautomake
}

src_compile() {
	local myconf
	# Funtoo tree via Jeff from bug attachment: fix bug #263269
	use amd64 && myconf="--with-boost-filesystem=mt --with-boost-serialization=mt --with-boost-system=mt"
	econf ${myconf} `use_enable nls` || die
	emake || die
}

src_install() {
	make DESTDIR="${D}" install || die "make install failed"
	dodoc AUTHORS ChangeLog README
}

pkg_postinst() {
	einfo "Please see http://www.arg0.net/encfsintro"
	einfo "if this is your first time using encfs."
}
