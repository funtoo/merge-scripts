# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/iodine/iodine-0.5.2.ebuild,v 1.1 2009/09/26 19:24:36 vostorga Exp $

inherit linux-info eutils

DESCRIPTION="IP over DNS tunnel"
HOMEPAGE="http://code.kryo.se/iodine/"
SRC_URI="http://code.kryo.se/${PN}/${P}.tar.gz"

CONFIG_CHECK="TUN"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

RDEPEND="sys-libs/zlib"
DEPEND="${RDEPEND}
	test? ( dev-libs/check )"

src_unpack(){
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-Makefile.patch
}

src_compile() {
	emake CC="$(tc-getCC)" || die "make failed"
}

src_install() {
	dobin bin/iodine bin/iodined || die "binaries failed"
	dodoc README CHANGELOG || die "docs failed"
	doman man/iodine.8 || die "man failed"

	newinitd "${FILESDIR}"/iodined.init iodined || die "initd failed"
	newconfd "${FILESDIR}"/iodined.conf iodined || die "confd failed"
	keepdir /var/empty
}
