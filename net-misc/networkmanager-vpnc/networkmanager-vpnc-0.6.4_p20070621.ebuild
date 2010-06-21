# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/networkmanager-vpnc/networkmanager-vpnc-0.6.4_p20070621.ebuild,v 1.5 2009/04/22 14:22:10 rbu Exp $

inherit gnome2 eutils autotools versionator

# NetworkManager likes itself with capital letters
MY_P=${P/networkmanager/NetworkManager}
MYPV_MINOR=$(get_version_component_range 1-2)

DESCRIPTION="NetworkManager vpnc plugin for daemon and client configuration."
HOMEPAGE="http://www.gnome.org/projects/NetworkManager/"
#SRC_URI="http://dev.gentoo.org/~rbu/distfiles/${MY_P}.tar.gz"
SRC_URI="mirror://gentoo/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="crypt doc gnome"

RDEPEND=">=sys-apps/dbus-0.60
	>=sys-apps/hal-0.5
	sys-apps/iproute2
	>=dev-libs/libnl-1.0_pre6
	>=net-misc/dhcdbd-1.4
	>=net-wireless/wireless-tools-28_pre9
	>=net-wireless/wpa_supplicant-0.4.8
	=net-misc/networkmanager-${MYPV_MINOR}*
	>=net-misc/vpnc-0.3.3
	>=dev-libs/glib-2.8
	>=x11-libs/libnotify-0.3.2
	gnome? ( >=x11-libs/gtk+-2.8
		>=gnome-base/libglade-2
		>=gnome-base/gnome-keyring-0.4
		>=gnome-base/gconf-2
		>=gnome-base/libgnomeui-2 )
	crypt? ( dev-libs/libgcrypt )"

DEPEND="${RDEPEND}
	dev-util/pkgconfig
	dev-util/intltool"

S=${WORKDIR}/${MY_P}

DOCS="AUTHORS ChangeLog NEWS README"
USE_DESTDIR="1"

G2CONF="${G2CONF} \
	`use_with crypt gcrypt` \
	`use_with gnome` \
	--disable-more-warnings \
	--with-dbus-sys=/etc/dbus-1/system.d \
	--enable-notification-icon"

src_unpack () {
	unpack ${A}
	cd "${S}"
	# Gentoo puts vpnc somewhere that the source doesn't expect.
	epatch "${FILESDIR}"/nm-vpnc-path.patch
	# Match the same dbus permissions as NetworkManager
	epatch "${FILESDIR}"/nm-vpnc-dbus_conf.patch

	epatch "${FILESDIR}"/${P}-service-name.patch
	eautoreconf
	intltoolize --force || die "intltoolize failed"
}
