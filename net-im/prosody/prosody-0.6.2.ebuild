# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-im/prosody/prosody-0.6.2.ebuild,v 1.2 2010/05/27 12:56:31 djc Exp $

EAPI="2"

inherit eutils versionator multilib

MY_PV=$(replace_version_separator 3 '')
DESCRIPTION="Prosody is a flexible communications server for Jabber/XMPP written in Lua."
HOMEPAGE="http://prosody.im/"
SRC_URI="http://prosody.im/depot/${MY_PV}/${PN}-${MY_PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="ssl"

DEPEND="net-im/jabber-base
		>=dev-lang/lua-5.1
		dev-libs/luasocket
		ssl? ( dev-libs/luasec )
		dev-libs/luaexpat
		dev-libs/luafilesystem
		>=net-dns/libidn-1.1
		>=dev-libs/openssl-0.9.8"
RDEPEND="${DEPEND}"

PROVIDE="virtual/jabber-server"

S="${WORKDIR}/${PN}-${MY_PV}"

JABBER_ETC="/etc/jabber"
JABBER_SPOOL="/var/spool/jabber"

src_prepare() {
	epatch "${FILESDIR}/${PN}-0.6.2-cfg.lua.patch"
	sed -i "s!MODULES = \$(DESTDIR)\$(PREFIX)/lib/!MODULES = \$(DESTDIR)\$(PREFIX)/$(get_libdir)/!" Makefile
	sed -i "s!SOURCE = \$(DESTDIR)\$(PREFIX)/lib/!SOURCE = \$(DESTDIR)\$(PREFIX)/$(get_libdir)/!" Makefile
	sed -i "s!INSTALLEDSOURCE = \$(PREFIX)/lib/!INSTALLEDSOURCE = \$(PREFIX)/$(get_libdir)/!" Makefile
	sed -i "s!INSTALLEDMODULES = \$(PREFIX)/lib/!INSTALLEDMODULES = \$(PREFIX)/$(get_libdir)/!" Makefile
}

src_configure() {
	./configure --prefix="/usr" \
		--sysconfdir="${JABBER_ETC}" \
		--datadir="${JABBER_SPOOL}" \
		--with-lua-lib=/usr/$(get_libdir)/lua \
		--require-config || die "configure failed"
}

src_install() {
	DESTDIR="${D}" emake install || die "make failed"
	newinitd "${FILESDIR}/${PN}".initd ${PN}
}

src_test() {
	cd tests
	./run_tests.sh
}
