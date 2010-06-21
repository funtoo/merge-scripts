# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

DESCRIPTION="Free client for Cisco AnyConnect SSL VPN software"
HOMEPAGE="http://www.infradead.org/openconnect.html"
SRC_URI="ftp://ftp.infradead.org/pub/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=">=dev-libs/openssl-0.9.7
	dev-libs/libxml2"

RDEPEND="${DEPEND}"
#	resolvconf? ( net-dns/openresolv )

src_compile() {
	emake OPT_FLAGS="${CFLAGS}"|| die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc README.DTLS README.SecurID TODO
	dohtml ${PN}.html
}

pkg_postinst() {
	elog "Don't forget to turn on TUN support in the kernel."
}
