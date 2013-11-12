# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-im/empathy/empathy-2.34.0-r2.ebuild,v 1.11 2013/07/23 01:08:37 tetromino Exp $

EAPI="4"
GCONF_DEBUG="yes"
GNOME2_LA_PUNT="yes"
GNOME_TARBALL_SUFFIX="bz2"
PYTHON_DEPEND="2:2.5"

inherit eutils gnome2 multilib python

DESCRIPTION="Telepathy client and library using GTK+"
HOMEPAGE="http://live.gnome.org/Empathy"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="alpha amd64 ~ia64 ppc ~sparc x86 ~x86-linux"
# FIXME: Add location support once geoclue stops being idiotic with automagic deps
IUSE="eds nautilus networkmanager spell test webkit"

# FIXME: libnotify & libcanberra hard deps
# gst-plugins-bad is required for the valve plugin. This should move to good
# eventually at which point the dep can be dropped
RDEPEND=">=dev-libs/glib-2.27.2:2
	>=x11-libs/gtk+-2.22:2
	>=dev-libs/dbus-glib-0.51
	>=net-libs/telepathy-glib-0.14.1
	>=media-libs/libcanberra-0.4[gtk]
	>=x11-libs/libnotify-0.7
	>=gnome-base/gnome-keyring-2.26
	<gnome-base/gnome-keyring-3
	>=net-libs/gnutls-2.8.5
	>=dev-libs/folks-0.4

	>=dev-libs/libunique-1.1.6:1
	net-libs/farsight2
	>=media-libs/gstreamer-0.10.32:0.10
	>=media-libs/gst-plugins-base-0.10.32:0.10
	media-libs/gst-plugins-bad:0.10
	media-plugins/gst-plugins-gconf:0.10
	>=net-libs/telepathy-farsight-0.0.14
	dev-libs/libxml2
	x11-libs/libX11
	net-im/telepathy-connection-managers
	>=net-im/telepathy-logger-0.2.0

	eds? ( >=gnome-extra/evolution-data-server-1.2 )
	nautilus? ( >=gnome-extra/nautilus-sendto-2.31.7 )
	networkmanager? ( >=net-misc/networkmanager-0.7 )
	spell? (
		>=app-text/enchant-1.2
		>=app-text/iso-codes-0.35 )
	webkit? ( >=net-libs/webkit-gtk-1.1.15:2 )
"
DEPEND="${RDEPEND}
	app-text/scrollkeeper
	>=app-text/gnome-doc-utils-0.17.3
	>=dev-util/intltool-0.35.0
	virtual/pkgconfig
	test? (
		sys-apps/grep
		>=dev-libs/check-0.9.4 )
	dev-libs/libxslt
"
PDEPEND=">=net-im/telepathy-mission-control-5.7.6"

pkg_setup() {
	# Build time python tools needs python2
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	DOCS="CONTRIBUTORS AUTHORS ChangeLog NEWS README"

	# call support needs unreleased telepathy-farstream
	# map disabled due to clutter-gtk-0.10 removal, bug #435164
	G2CONF="${G2CONF}
		--enable-silent-rules
		--disable-coding-style-checks
		--disable-schemas-compile
		--disable-static
		--disable-call
		--disable-location
		--disable-control-center-embedding
		--disable-Werror
		$(use_enable debug)
		$(use_with eds)
		--disable-map
		$(use_enable nautilus nautilus-sendto)
		$(use_with networkmanager connectivity nm)
		$(use_enable spell)
		$(use_enable webkit)"

	epatch "${FILESDIR}"/${P}-auth-dialog-crash-fix.patch

	# Fix script injection vulnerability (CVE-2011-3635), bug #388051
	epatch "${FILESDIR}"/${P}-CVE-2011-3635.patch

	# Fix compilation error due missing header, bug #388203
	epatch "${FILESDIR}"/${P}-missing-include.patch

	python_convert_shebangs -r 2 .
	gnome2_src_prepare
}

src_test() {
	unset DBUS_SESSION_BUS_ADDRESS
	emake check
}

pkg_postinst() {
	gnome2_pkg_postinst
	elog "Empathy needs telepathy's connection managers to use any IM protocol."
	elog "See the USE flags on net-im/telepathy-connection-managers"
	elog "to install them."
}
