# Distributed under the terms of the GNU General Public License v2

EAPI="5"
GCONF_DEBUG="yes"
GNOME2_LA_PUNT="yes" # gmodule is used, which uses dlopen

inherit autotools eutils gnome2

DESCRIPTION="GNOME Desktop Configuration Tool"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2+"
SLOT="2"
IUSE="+bluetooth +colord +cups +gnome-online-accounts +i18n input_devices_wacom kerberos +networkmanager +socialweb systemd v4l"
KEYWORDS="~*"

# XXX: NetworkManager-0.9 support is automagic, make hard-dep once it's released
#
# gnome-session-2.91.6-r1 is needed so that 10-user-dirs-update is run at login
# g-s-d[policykit] needed for bug #403527
COMMON_DEPEND="
	>=dev-libs/glib-2.31:2
	>=x11-libs/gdk-pixbuf-2.23.0:2
	>=x11-libs/gtk+-3.5.13:3
	>=gnome-base/gsettings-desktop-schemas-3.5.91
	>=gnome-base/gnome-desktop-3.5.91:3=
	>=gnome-base/gnome-settings-daemon-3.6[colord?,policykit]
	>=gnome-base/libgnomekbd-2.91.91

	app-text/iso-codes
	dev-libs/libpwquality
	dev-libs/libxml2:2
	gnome-base/gnome-menus:3
	gnome-base/libgtop:2
	media-libs/fontconfig

	>=media-libs/libcanberra-0.13[gtk3]
	>=media-sound/pulseaudio-2[glib]
	>=sys-auth/polkit-0.97
	>=sys-power/upower-0.9.1
	>=x11-libs/libnotify-0.7.3

	x11-apps/xmodmap
	x11-libs/libX11
	x11-libs/libXxf86misc
	>=x11-libs/libXi-1.2

	bluetooth? ( >=net-wireless/gnome-bluetooth-3.5.5:= )
	colord? ( >=x11-misc/colord-0.1.8 )
	cups? ( >=net-print/cups-1.4[dbus] )
	gnome-online-accounts? ( >=net-libs/gnome-online-accounts-3.5.90 )
	i18n? ( >=app-i18n/ibus-1.4.99 )
	input_devices_wacom? (
		>=dev-libs/libwacom-0.6
		>=x11-libs/libXi-1.2 )
	kerberos? ( virtual/krb5 )
	networkmanager? (
		>=gnome-extra/nm-applet-0.9.1.90
		>=net-misc/networkmanager-0.8.997 )
	socialweb? ( net-libs/libsocialweb )
	systemd? ( >=sys-apps/systemd-31 )
	v4l? (
		media-libs/gstreamer:1.0
		media-libs/clutter-gtk:1.0
		>=media-video/cheese-3.5.91 )
"
# <gnome-color-manager-3.1.2 has file collisions with g-c-c-3.1.x
RDEPEND="${COMMON_DEPEND}
	gnome-base/gnome-settings-daemon[input_devices_wacom?]
	sys-apps/accountsservice
	x11-themes/gnome-icon-theme-symbolic
	colord? ( >=gnome-extra/gnome-color-manager-3 )
	cups? (
		>=app-admin/system-config-printer-gnome-1.3.5
		net-print/cups-pk-helper )
	!systemd? (
		app-admin/openrc-settingsd
		sys-auth/consolekit )

	!<gnome-base/gdm-2.91.94
	!<gnome-extra/gnome-color-manager-3.1.2
	!gnome-extra/gnome-media[pulseaudio]
	!<gnome-extra/gnome-media-2.32.0-r300
	!<net-wireless/gnome-bluetooth-3.3.2
"
# PDEPEND to avoid circular dependency
PDEPEND=">=gnome-base/gnome-session-2.91.6-r1"
DEPEND="${COMMON_DEPEND}
	x11-proto/xproto
	x11-proto/xf86miscproto
	x11-proto/kbproto

	dev-libs/libxml2:2
	dev-libs/libxslt
	>=dev-util/intltool-0.40.1
	>=sys-devel/gettext-0.17
	virtual/pkgconfig

	cups? ( sys-apps/sed )

	gnome-base/gnome-common
"
# Needed for autoreconf
#	gnome-base/gnome-common

src_prepare() {
	# Make some panels optional; requires eautoreconf
	epatch "${FILESDIR}/${PN}-3.5.91-optional-bt-colord-goa-wacom.patch"
	# https://bugzilla.gnome.org/show_bug.cgi?id=686840
	epatch "${FILESDIR}/${PN}-3.5.91-optional-kerberos.patch"
	# Fix some absolute paths to be appropriate for Gentoo
	epatch "${FILESDIR}/${PN}-3.5.91-gentoo-paths.patch"
	# Needed for g-c-c 3.6.3 and PulseAudio >2.1. Remove in 3.6.4.
	epatch "${FILESDIR}/${P}-pulseaudio-3-fix.patch"
	eautoreconf

	gnome2_src_prepare

	# panels/datetime/Makefile.am gets touched as a result of something in our
	# src_prepare(). We need to touch timedated{c,h} to prevent them from being
	# regenerated (bug #415901)
	[[ -f panels/datetime/timedated.h ]] && touch panels/datetime/timedated.h
	[[ -f panels/datetime/timedated.c ]] && touch panels/datetime/timedated.c
}

src_configure() {
	G2CONF="${G2CONF}
		--disable-update-mimedb
		--disable-static
		--enable-documentation
		$(use_enable bluetooth)
		$(use_enable colord color)
		$(use_enable cups)
		$(use_enable gnome-online-accounts goa)
		$(use_enable i18n ibus)
		$(use_enable input_devices_wacom wacom)
		$(use_with socialweb libsocialweb)
		$(use_enable systemd)
		$(use_with v4l cheese)"
	# XXX: $(use_with kerberos) # for 3.7.x
	if ! use kerberos; then
		G2CONF+=" KRB5_CONFIG=$(type -P true)"
	fi
	DOCS="AUTHORS ChangeLog NEWS README TODO"
	gnome2_src_configure
}
