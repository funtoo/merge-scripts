# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

EAPI="1"
inherit autotools eutils gnome2 multilib

DESCRIPTION="A browser plug-in for GNOME MPlayer."
HOMEPAGE="http://code.google.com/p/gecko-mediaplayer"
SRC_URI="http://${PN}.googlecode.com/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="gnome"

RDEPEND="
	dev-libs/glib:2
	net-libs/xulrunner:1.9
	dev-libs/nspr
	>=sys-apps/dbus-0.95
	>=dev-libs/dbus-glib-0.70
	>=media-video/gnome-mplayer-${PV}
	gnome? ( gnome-base/gconf:2 )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	sys-devel/gettext"

G2CONF="
	$(use_with gnome gconf)
	$(use !gnome && echo "--disable-schemas-install")"

DOCS="ChangeLog INSTALL
	DOCS/tech/javascript.txt"

src_unpack() {
	gnome2_src_unpack

	epatch "${FILESDIR}"/force-libxul-${PV}.patch
	epatch "${FILESDIR}"/default-libdir-${PV}.patch
	epatch "${FILESDIR}"/sandbox-violation-${PV}.patch
	eautoreconf || die "eautoreconf failed"
}

src_install() {
	gnome2_src_install

	# remove docs in DOCS and empty dir
	rm -rf "${D}"/usr/share/doc/${PN}
	rmdir -p "${D}"/var/lib

	# move plugins to correct location and clean empty dirs
	dodir /usr/$(get_libdir)/nsbrowser/plugins
	mv "${D}"/usr/$(get_libdir)/mozilla/plugins/${PN}* \
		"${D}"/usr/$(get_libdir)/nsbrowser/plugins || die "mv plugins failed."
	rmdir -p "${D}"/usr/$(get_libdir)/mozilla/plugins
}

