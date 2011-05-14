# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-voip/telepathy-salut/telepathy-salut-0.4.0.ebuild,v 1.5 2011/03/22 20:11:02 ranger Exp $

EAPI="3"
PYTHON_DEPEND="2:2.4"

inherit base python

DESCRIPTION="A link-local XMPP connection manager for Telepathy"
HOMEPAGE="http://telepathy.freedesktop.org/wiki/Components"
SRC_URI="http://telepathy.freedesktop.org/releases/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 ia64 ppc sparc x86"
IUSE="test"

# FIXME: Automagic useless libasyncns check ?
RDEPEND="dev-libs/libxml2
	>=dev-libs/glib-2.16
	>=sys-apps/dbus-1.1.0
	>=net-libs/telepathy-glib-0.7.36
	>=net-dns/avahi-0.6.22
	net-libs/libsoup:2.4
	sys-apps/util-linux"
DEPEND="${RDEPEND}
	test? (
		net-libs/libgsasl
		app-text/xmldiff
		>=dev-libs/check-0.9.4
		dev-python/twisted-words )
	dev-libs/libxslt"

pkg_setup() {
	DOCS="AUTHORS ChangeLog NEWS README"
	python_set_active_version 2
}

src_prepare() {
	python_convert_shebangs -r 2 .
}

src_configure() {
	econf \
		--docdir=/usr/share/doc/${PF}
	# too much changes required: $(use_enable test avahi-tests)
}
