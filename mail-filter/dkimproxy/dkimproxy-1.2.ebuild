# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils perl-module

DESCRIPTION="An SMTP proxy that signs and/or verifies emails using the Mail::DKIM module"
HOMEPAGE="http://dkimproxy.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

DEPEND=">=dev-perl/Mail-DKIM-0.32
		dev-perl/Error
		>=dev-perl/net-server-0.91"
RDEPEND="${DEPEND}"

pkg_setup() {
	enewgroup dkim
	enewuser dkim -1 -1 -1 dkim
}

src_compile(){
	perlinfo
	export perllibdir=${VENDOR_LIB}
	econf || die "econf failed"
	emake || die "emake failed"
}

src_install(){
	emake DESTDIR="${D}" install || die "emake install failed"
	dosed '1s:^\(#!/usr/bin/perl\).*$:\1:' /usr/bin/dkimproxy.{in,out}
	for i in in out; do
		newinitd ${FILESDIR}/dkimproxy.init dkimproxy_${i}
	done
	dodoc README NEWS TODO
	diropts -odkim -gdkim -m0750
	dodir /etc/dkimproxy
}

pkg_postinst() {
	einfo
	einfo "If you want to sign outgoing mail using DKIM, you might want"
	einfo "to generate an RSA keypair now:"
	einfo
	einfo "umask 0027"
	einfo "openssl genrsa -out /etc/dkimproxy/privkey.pem 1024"
	einfo "openssl rsa -in /etc/dkimproxy/privkey.pem -pubout -out /etc/dkimproxy/pubkey.pem"
	einfo "chgrp dkim /etc/dkimproxy/*.pem"
	einfo
}
