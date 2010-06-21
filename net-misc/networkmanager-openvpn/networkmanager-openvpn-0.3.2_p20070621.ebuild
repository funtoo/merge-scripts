# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/networkmanager-openvpn/networkmanager-openvpn-0.3.2_p20070621.ebuild,v 1.4 2009/04/22 14:22:08 rbu Exp $

inherit gnome2 eutils autotools

# NetworkManager likes itself with capital letters
MY_P=${P/networkmanager/NetworkManager}

DESCRIPTION="NetworkManager OpenVPN plugin."
HOMEPAGE="http://www.gnome.org/projects/NetworkManager/"
#SRC_URI="http://dev.gentoo.org/~rbu/distfiles/${MY_P}.tar.gz"
SRC_URI="mirror://gentoo/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="crypt doc gnome"

RDEPEND=">=sys-apps/dbus-0.35.2
	>=sys-apps/hal-0.5
	sys-apps/iproute2
	>=net-misc/dhcdbd-1.4
	>=net-wireless/wireless-tools-28_pre9
	>=dev-libs/glib-2.8
	=net-misc/networkmanager-0.6*
	gnome? ( >=x11-libs/gtk+-2.8
		>=gnome-base/libglade-2
		>=gnome-base/gnome-keyring-0.4
		>=gnome-base/gconf-2
		>=gnome-base/libgnomeui-2 )
	!gnome? ( >=gnome-base/libglade-2
		>=gnome-base/gnome-keyring-0.4
		>=gnome-base/gconf-2 )
	>=net-misc/openvpn-2.0.5
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

	epatch "${FILESDIR}/${P}-service-name.patch"
	intltoolize --copy --automake --force || die "intltoolize failed"
	eautoreconf
}
