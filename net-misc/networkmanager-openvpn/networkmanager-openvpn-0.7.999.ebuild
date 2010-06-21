# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/networkmanager-openvpn/networkmanager-openvpn-0.7.999.ebuild,v 1.2 2010/01/28 15:26:47 nirbheek Exp $

EAPI="2"

inherit eutils gnome.org

# NetworkManager likes itself with capital letters
MY_PN=${PN/networkmanager/NetworkManager}

DESCRIPTION="NetworkManager OpenVPN plugin."
HOMEPAGE="http://www.gnome.org/projects/NetworkManager/"
SRC_URI="${SRC_URI//${PN}/${MY_PN}}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="gnome"

RDEPEND="
	>=net-misc/networkmanager-${PV}
	>=net-misc/openvpn-2.1_rc9
	>=dev-libs/dbus-glib-0.74
	gnome? (
		>=x11-libs/gtk+-2.6
		gnome-base/gconf:2
		gnome-base/gnome-keyring
		gnome-base/libglade:2.0
		gnome-base/libgnomeui
	)"

DEPEND="${RDEPEND}
	sys-devel/gettext
	dev-util/intltool
	dev-util/pkgconfig"

S="${WORKDIR}/${MY_PN}-${PV}"

# FAIL: (tls-import-data) unexpected 'ca' secret value
RESTRICT="test"

src_configure() {
	ECONF="--disable-more-warnings
		$(use_with gnome)"

	econf ${ECONF}
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	dodoc AUTHORS ChangeLog NEWS README || die "dodoc failed"
}
