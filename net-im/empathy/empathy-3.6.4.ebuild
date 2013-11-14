# Distributed under the terms of the GNU General Public License v2

EAPI="5"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
PYTHON_COMPAT=( python2_{6,7} )

inherit gnome2 python-any-r1 virtualx

DESCRIPTION="Telepathy instant messaging and video/audio call client for GNOME"
HOMEPAGE="http://live.gnome.org/Empathy"

LICENSE="GPL-2 CC-BY-SA-3.0 FDL-1.3 LGPL-2.1"
SLOT="0"
IUSE="debug +geocode +geoloc gnome gnome-online-accounts +map sendto spell test +v4l"
KEYWORDS="~*"

# gdk-pixbuf and pango extensively used in libempathy-gtk
COMMON_DEPEND="
	>=dev-libs/glib-2.33.3:2
	x11-libs/gdk-pixbuf:2
	>=x11-libs/gtk+-3.5.1:3
	x11-libs/pango
	>=dev-libs/dbus-glib-0.51
	>=dev-libs/folks-0.7.3:=[telepathy]
	dev-libs/libgee:0=
	>=app-crypt/libsecret-0.5
	>=media-libs/libcanberra-0.25[gtk3]
	>=net-libs/gnutls-2.8.5:=
	>=net-libs/webkit-gtk-1.3.13:3
	>=x11-libs/libnotify-0.7:=

	media-libs/gstreamer:1.0
	>=media-libs/clutter-1.10.0:1.0
	>=media-libs/clutter-gtk-1.1.2:1.0
	media-libs/clutter-gst:2.0
	media-libs/cogl:1.0=

	net-libs/farstream:0.2
	>=net-libs/telepathy-farstream-0.5:=
	>=net-libs/telepathy-glib-0.19.9
	>=net-im/telepathy-logger-0.2.13:=

	app-crypt/gcr
	dev-libs/libxml2:2
	gnome-base/gsettings-desktop-schemas
	media-sound/pulseaudio[glib]
	net-libs/libsoup:2.4
	x11-libs/libX11

	geocode? ( ~sci-geosciences/geocode-glib-0.99.0 )
	geoloc? ( >=app-misc/geoclue-0.12 )
	gnome-online-accounts? ( >=net-libs/gnome-online-accounts-3.5.1 )
	map? (
		>=media-libs/clutter-1.7.14:1.0
		>=media-libs/clutter-gtk-0.90.3:1.0
		>=media-libs/libchamplain-0.12.1:0.12[gtk] )
	sendto? ( >=gnome-extra/nautilus-sendto-2.90.0 )
	spell? (
		>=app-text/enchant-1.2
		>=app-text/iso-codes-0.35 )
	v4l? (
		media-plugins/gst-plugins-v4l2:1.0
		>=media-video/cheese-3.4:=
		virtual/udev[gudev] )"
# >=empathy-3.4 is incompatible with telepathy-rakia-0.6, bug #403861
RDEPEND="${COMMON_DEPEND}
	media-libs/gst-plugins-base:1.0
	net-im/telepathy-connection-managers
	!<net-voip/telepathy-rakia-0.7
	x11-themes/gnome-icon-theme-symbolic
	gnome? ( gnome-extra/gnome-contacts )"
DEPEND="${COMMON_DEPEND}
	${PYTHON_DEPS}
	dev-libs/libxml2:2
	dev-libs/libxslt
	>=dev-util/intltool-0.50.0
	virtual/pkgconfig
	test? (
		sys-apps/grep
		>=dev-libs/check-0.9.4 )
"
PDEPEND=">=net-im/telepathy-mission-control-5.14"

src_configure() {
	DOCS="CONTRIBUTORS AUTHORS ChangeLog NEWS README"
	gnome2_src_configure \
		--disable-Werror \
		--disable-coding-style-checks \
		--disable-static \
		--disable-ubuntu-online-accounts \
		--enable-gst-1.0 \
		$(use_enable debug) \
		$(use_enable geocode) \
		$(use_enable geoloc location) \
		$(use_enable gnome-online-accounts goa) \
		$(use_enable map) \
		$(use_enable sendto nautilus-sendto) \
		$(use_enable spell) \
		$(use_enable v4l gudev) \
		$(use_with v4l cheese) \
		ITSTOOL=$(type -P true)
}

src_test() {
	Xemake check
}

pkg_postinst() {
	gnome2_pkg_postinst
	elog "Empathy needs telepathy's connection managers to use any IM protocol."
	elog "See the USE flags on net-im/telepathy-connection-managers"
	elog "to install them."
}
