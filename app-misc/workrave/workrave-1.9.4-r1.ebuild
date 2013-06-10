# Distributed under the terms of the GNU General Public License v2

EAPI="4"
GCONF_DEBUG="yes"
PYTHON_DEPEND="2:2.5"

inherit eutils gnome2 python

DESCRIPTION="Helpful utility to attack Repetitive Strain Injury (RSI)"
HOMEPAGE="http://www.workrave.org/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="*"
IUSE="dbus doc distribution gnome gstreamer nls pulseaudio test"

RDEPEND=">=dev-libs/glib-2.10:2
	>=gnome-base/gconf-2
	>=x11-libs/gtk+-2.8:2
	>=dev-cpp/gtkmm-2.10:2.4
	>=dev-cpp/glibmm-2.10:2
	>=dev-libs/libsigc++-2:2
	dbus? (
		>=sys-apps/dbus-1.2
		dev-libs/dbus-glib )
	distribution? ( >=net-libs/gnet-2 )
	gnome? (
		|| ( gnome-base/gnome-panel[bonobo] <gnome-base/gnome-panel-2.32 )
		>=gnome-base/libbonobo-2
		>=gnome-base/orbit-2.8.3 )
	gstreamer? (
		>=media-libs/gstreamer-0.10:0.10
		>=media-libs/gst-plugins-base-0.10:0.10 )
	pulseaudio? ( >=media-sound/pulseaudio-0.9.15 )
	x11-libs/libSM
	x11-libs/libX11
	x11-libs/libXtst
	x11-libs/libXt
	x11-libs/libXmu
	x11-libs/libXScrnSaver"

DEPEND="${RDEPEND}
	x11-proto/xproto
	x11-proto/inputproto
	x11-proto/recordproto
	dev-python/cheetah
	virtual/pkgconfig
	doc? (
		app-text/docbook-sgml-utils
		app-text/xmlto )
	nls? ( sys-devel/gettext )"

pkg_setup() {
	DOCS="AUTHORS NEWS README TODO"
	G2CONF="${G2CONF}
		--without-arts
		--disable-kde
		--enable-gconf
		--disable-x11-monitoring-fallback
		--disable-gnome3
		--disable-experimental
		--disable-xml
		$(use_enable dbus)
		$(use_enable doc manual)
		$(use_enable distribution)
		$(use_enable gnome)
		$(use_enable gstreamer)
		$(use_enable nls)
		$(use_enable pulseaudio pulse)
		$(use_enable test tests)"

	python_set_active_version 2
	python_pkg_setup
}
