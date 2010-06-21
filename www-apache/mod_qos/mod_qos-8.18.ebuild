# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-apache/mod_qos/mod_qos-8.18.ebuild,v 1.1 2009/09/18 16:14:19 hollow Exp $

EAPI="2"

inherit apache-module

DESCRIPTION="A QOS module for the apache webserver"
HOMEPAGE="http://mod-qos.sourceforge.net/"
SRC_URI="mirror://sourceforge/mod-qos/${P}-src.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="dev-libs/openssl"
RDEPEND="${DEPEND}"

APXS2_S="${S}/apache2"
APACHE2_MOD_CONF="10_${PN}"
APACHE2_MOD_DEFINE="QOS"

need_apache2

src_prepare() {
	sed -i -e '/strip/d' tools/Makefile
}

src_compile() {
	apache-module_src_compile
	emake -C "${S}/tools"
}

src_install() {
	apache-module_src_install
	dobin tools/qslog
	dodoc doc/CHANGES.txt
	rm doc/*.txt
	dohtml doc/*
}
