# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit webapp eutils depend.php

DESCRIPTION="A web client written in php/AJAX"
HOMEPAGE="http://pitchfork.remiss.org"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.bz2"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"

RDEPEND="virtual/httpd-php
	dev-php/PEAR-Net_Socket"

S="${WORKDIR}/${P}"

pkg_setup() {
	webapp_pkg_setup

	if has_version 'dev-lang/php' ; then
		require_php_with_use simplexml json session
	fi
}

src_install() {
	webapp_src_preinst

	cd ${WORKDIR}/${PN}

	dodoc "doc/pitchfork.conf"
	dodoc "doc/pitchfork_domain.conf"
	dodoc "ChangeLog"
	dodoc "CREDITS"
	dodoc "README"

	cp -r . "${D}/${MY_HTDOCSDIR}"

	webapp_serverowned -R ${MY_HTDOCSDIR}/config
	webapp_src_install
}
