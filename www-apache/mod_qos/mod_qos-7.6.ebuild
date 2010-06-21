# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit apache-module

DESCRIPTION="A QOS module for the apache webserver"
HOMEPAGE="http://mod-qos.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}-src.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="dev-libs/apr
	dev-libs/openssl"
RDEPEND="${DEPEND}"

APACHE2_MOD_CONF=10_${PN}
APACHE2_MOD_DEFINE="QOS"
APXS2_S=${S}/apache2
APACHE2_MOD_FILE=${APXS2_S}/.libs/${PN}.so
APACHE2_EXECFILES="${APXS2_S}"/.libs/mod_qos_control.so
DOCFILES=${S}/doc/*.html

need_apache2

src_compile() {
	local MYOPTS="-c mod_qos.c"
	cd "${APXS2_S}"
	${APXS} ${MYOPTS} || die "compile failed"
	MYOPTS="-c mod_qos.lo"
	${APXS} ${MYOPTS} || die "compile failed"
	MYOPTS="-c mod_qos_control.c"
	${APXS} ${MYOPTS} || die "compile failed"
	MYOPTS="-c mod_qos_control.lo"
	${APXS} ${MYOPTS} || die "compile failed"
	cd "${S}"/tools
	sed -i -e '/strip/ d' Makefile || die "sed tools makefile failed"
	emake || die "emake failed"
}
src_install() {
	apache-module_src_install
	dobin tools/qslog || die "Install qslog failed"
}
