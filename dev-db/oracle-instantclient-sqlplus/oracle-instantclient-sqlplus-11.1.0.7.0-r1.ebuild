# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-db/oracle-instantclient-sqlplus/oracle-instantclient-sqlplus-11.1.0.7.0-r1.ebuild,v 1.1 2009/05/04 17:00:05 dertobi123 Exp $

inherit eutils

MY_P_x86="${PN/oracle-/}-linux32-${PV/7.0/7}"
MY_P_amd64="${PN/oracle-instantclient-/}-${PV}-linux-x86_64"

S="${WORKDIR}"
DESCRIPTION="Oracle 11g client installation for Linux: SQL*Plus"
HOMEPAGE="http://www.oracle.com/technology/tech/oci/instantclient/index.html"
SRC_URI="amd64? ( ${MY_P_amd64}.zip )
		 x86? ( ${MY_P_x86}.zip )"

LICENSE="OTN"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="fetch"
IUSE=""

RDEPEND=">=dev-db/oracle-instantclient-basic-${PV}"
DEPEND="${RDEPEND}
	app-arch/unzip"

pkg_setup() {
	MY_P=MY_P_${ARCH}
	export MY_P=${!MY_P}
}

pkg_nofetch() {
	eerror "Please go to:"
	eerror "  ${HOMEPAGE}"
	eerror "select your platform and download the"
	eerror "SQL*Plus package.  Put it in:"
	eerror "  ${DISTDIR}"
	eerror "after downloading it."
}

src_unpack() {
	unzip "${DISTDIR}"/${MY_P}.zip
}

src_install() {
	dodir /usr/$(get_libdir)/oracle/${PV}/client/lib
	cd "${S}"/instantclient_11_1
	insinto /usr/$(get_libdir)/oracle/${PV}/client/lib
	doins libsqlplus.so libsqlplusic.so
	insinto /usr/$(get_libdir)/oracle/${PV}/client/sqlplus/admin/
	doins glogin.sql

	dodir /usr/$(get_libdir)/oracle/${PV}/client/bin
	cd "${S}"/instantclient_11_1
	exeinto /usr/$(get_libdir)/oracle/${PV}/client/bin
	doexe sqlplus

	dodir /usr/bin
	dosym "${D}"/usr/$(get_libdir)/oracle/${PV}/client/bin/sqlplus /usr/bin/sqlplus
}

pkg_postinst() {
	elog "The SQL*Plus package for Oracle 11g has been installed."
	elog "You may wish to install the oracle-instantclient-jdbc (for"
	elog "the supplemental JDBC functionality) package as well."
	elog
	elog "If you have any questions, be sure to read the README:"
	elog "http://otn.oracle.com/docs/tech/sql_plus/10102/readme_ic.htm"
}
