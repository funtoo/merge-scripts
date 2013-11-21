# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/gnome-control-center/gnome-control-center-2.32.1-r1.ebuild,v 1.8 2012/05/05 05:38:11 jdhore Exp $

EAPI="3"
GCONF_DEBUG="yes"

inherit gnome2 eutils

DESCRIPTION="The gnome2 Desktop configuration tool"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2"
SLOT="2"
KEYWORDS="alpha amd64 arm ia64 ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~x86-solaris"
IUSE="eds"

# TODO: appindicator
# libgnomekbd-2.91 breaks API/ABI
RDEPEND="x11-libs/libXft
	>=x11-libs/libXi-1.2
	>=x11-libs/gtk+-2.20:2
	>=dev-libs/glib-2.28:2
	>=gnome-base/gconf-2.0:2
	>=gnome-base/librsvg-2.0:2
	>=gnome-base/nautilus-2.6
	>=media-libs/fontconfig-1
	>=dev-libs/dbus-glib-0.73
	>=x11-libs/libxklavier-4.0
	>=x11-wm/metacity-2.23.1
	>=gnome-base/libgnomekbd-2.31.2
	<gnome-base/libgnomekbd-2.91.0
	>=gnome-base/gnome-desktop-2.29.4:2
	>=gnome-base/gnome-menus-2.11.1:0
	gnome-base/gnome-settings-daemon

	dev-libs/libunique:1
	x11-libs/pango
	dev-libs/libxml2
	media-libs/freetype
	media-libs/libcanberra[gtk]

	eds? ( >=gnome-extra/evolution-data-server-1.7.90 )

	x11-apps/xmodmap
	x11-libs/libXScrnSaver
	x11-libs/libXext
	x11-libs/libX11
	x11-libs/libXxf86misc
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXcursor"
DEPEND="${RDEPEND}
	x11-proto/scrnsaverproto
	x11-proto/xextproto
	x11-proto/xproto
	x11-proto/xf86miscproto
	x11-proto/kbproto
	x11-proto/randrproto
	x11-proto/renderproto

	sys-devel/gettext
	>=dev-util/intltool-0.40
	virtual/pkgconfig
	dev-util/desktop-file-utils

	app-text/scrollkeeper
	>=app-text/gnome-doc-utils-0.10.1"
# Needed for autoreconf
#	gnome-base/gnome-common

pkg_setup() {
	G2CONF="${G2CONF}
		--disable-update-mimedb
		--disable-static
		--disable-appindicator
		$(use_enable eds aboutme)"
	DOCS="AUTHORS ChangeLog NEWS README TODO"
}

src_prepare() {
	gnome2_src_prepare

	# Use URL handlers for browser and mailer applications
	epatch "${FILESDIR}/${P}-mime-handler.patch"

	# When starting up, read current web and mail values
	epatch "${FILESDIR}/${P}-mime-handler2.patch"

	# Fix icons for new glib url handlers
	epatch "${FILESDIR}/${P}-mime-handler3.patch"

	# Do not show twice the configured background if it is a symlink to a known background
	epatch "${FILESDIR}/${P}-duplicated-background.patch"

	# Don't erase backgounds.xml, bug #344335
	epatch "${FILESDIR}/${P}-erase-background.patch"
}

src_install() {
	gnome2_src_install
	# gmodule is used to load plugins
	# (on POSIX systems gmodule uses dlopen)
	find "${ED}" -name "*.la" -delete || die "remove of la files failed"
}
