# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

DESCRIPTION="UFTP is an encrypted multicast file transfer program, designed to securely, reliably, and efficiently transfer files to multiple receivers simultaneously."
HOMEPAGE="http://www.tcnj.edu/~bush/uftp.html"
SRC_URI="http://www.tcnj.edu/~bush/downloads/${P}.tar"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="+ssl"

DEPEND="ssl? ( dev-libs/openssl )"
RDEPEND="${DEPEND}"

src_compile() {
	if use ssl; then
		emake CFLAGS="${CFLAGS}"
	else
		emake CFLAGS="${CFLAGS}" NO_ENCRYPTION=1
	fi
}

src_install() {
	make DESTDIR=${D} install || die "install failed"
	mv ${D}/bin ${D}/usr/bin || die "mv failed"
	newinitd "${FILESDIR}"/uftpd.init uftpd || die "newinitd failed"
	newconfd "${FILESDIR}"/uftpd.conf uftpd || die "newconfd failed"
	diropts -o nobody
	keepdir /var/log/uftpd || die "dodir failed"
	dodir /var/run/uftpd || die "dodir run failed"
	keepdir /var/tmp/uftpd || die "dodir tmp failed"
}
