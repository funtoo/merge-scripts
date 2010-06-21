# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils versionator

MY_PV=$(replace_version_separator 3 '')
DESCRIPTION="Prosody is a flexible communications server for Jabber/XMPP written in Lua."
HOMEPAGE="http://prosody.im/"
SRC_URI="http://prosody.im/depot/${MY_PV}/${PN}-${MY_PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="ssl"

JABBER_ETC="/etc/jabber"
JABBER_SPOOL="/var/spool/jabber"

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

src_prepare() {
	epatch "${FILESDIR}/${PN}-0.6.cfg.lua.patch"
}

src_configure() {
	./configure --prefix="/usr" \
		--sysconfdir="${JABBER_ETC}" \
		--datadir="${JABBER_SPOOL}" \
		--require-config
}

src_install() {
	DESTDIR="${D}" emake install
	newinitd "${FILESDIR}/${PN}".initd ${PN}
}
