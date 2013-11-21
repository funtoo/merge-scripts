# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/mail-client/evolution/evolution-2.32.3-r1.ebuild,v 1.19 2013/03/03 14:31:22 pacho Exp $

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
GNOME_TARBALL_SUFFIX="bz2"
PYTHON_DEPEND="python? 2:2.5"

inherit autotools eutils flag-o-matic gnome2 python versionator

MY_MAJORV=$(get_version_component_range 1-2)

DESCRIPTION="Integrated mail, addressbook and calendaring functionality"
HOMEPAGE="http://projects.gnome.org/evolution/"

SRC_URI="${SRC_URI} http://dev.gentoo.org/~pacho/gnome/${P}-patches.tar.xz"

# Note: explicitly "|| ( LGPL-2 LGPL-3 )", not "LGPL-2+".
LICENSE="|| ( LGPL-2 LGPL-3 ) GPL-2+ LGPL-2 FDL-1.2+ OPENLDAP"
SLOT="2.0"
KEYWORDS="alpha amd64 ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="clutter connman crypt gstreamer kerberos ldap networkmanager python ssl"

# We need a graphical pinentry frontend to be able to ask for the GPG
# password from inside evolution, bug 160302
PINENTRY_DEPEND="|| ( app-crypt/pinentry[gtk] app-crypt/pinentry-qt app-crypt/pinentry[qt4] )"

# contacts-map plugin requires libchaimplain and geoclue
# glade-3 support is for maintainers only per configure.ac
# mono plugin disabled as it's incompatible with 2.8 and lacks maintainance (see bgo#634571)
# pst is not mature enough and changes API/ABI frequently

RDEPEND=">=dev-libs/glib-2.25.12:2
	>=x11-libs/gtk+-2.20.0:2
	>=dev-libs/libunique-1.1.2:1
	>=gnome-base/gnome-desktop-2.26:2
	>=dev-libs/libgweather-2.25.3:2
	<dev-libs/libgweather-2.91:2
	media-libs/libcanberra[gtk]
	>=x11-libs/libnotify-0.3
	>=gnome-extra/evolution-data-server-${PV}[weather]
	=gnome-extra/evolution-data-server-${MY_MAJORV}*
	>=gnome-extra/gtkhtml-3.31.90:3.14
	>=gnome-base/gconf-2:2
	dev-libs/atk
	>=dev-libs/libxml2-2.7.3:2
	>=net-libs/libsoup-2.4:2.4
	>=media-gfx/gtkimageview-1.6
	>=x11-misc/shared-mime-info-0.22
	>=x11-themes/gnome-icon-theme-2.30.2.1
	>=dev-libs/libgdata-0.4

	clutter? (
		>=media-libs/clutter-1.0.0:1.0
		>=media-libs/clutter-gtk-0.90:1.0
		x11-libs/mx:1.0 )
	connman? ( net-misc/connman )
	crypt? ( || (
				  ( >=app-crypt/gnupg-2.0.1-r2
					${PINENTRY_DEPEND} )
				  =app-crypt/gnupg-1.4* ) )
	gstreamer? (
		>=media-libs/gstreamer-0.10:0.10
		>=media-libs/gst-plugins-base-0.10:0.10 )
	kerberos? ( virtual/krb5 )
	ldap? ( >=net-nds/openldap-2 )
	networkmanager? ( >=net-misc/networkmanager-0.7 )
	ssl? (
		>=dev-libs/nspr-4.6.1
		>=dev-libs/nss-3.11 )

	!<gnome-extra/evolution-exchange-2.32"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	>=dev-util/intltool-0.35.5
	sys-devel/gettext
	sys-devel/bison
	app-text/scrollkeeper
	>=app-text/gnome-doc-utils-0.9.1
	app-text/docbook-xml-dtd:4.1.2
	>=gnome-base/gnome-common-2.12
	>=dev-util/gtk-doc-am-1.9"
# eautoreconf needs:
#	>=gnome-base/gnome-common-2.12

pkg_setup() {
	python_pkg_setup
	python_set_active_version 2
}

src_prepare() {
	ELTCONF="--reverse-deps"
	DOCS="AUTHORS ChangeLog* HACKING MAINTAINERS NEWS* README"
	G2CONF="${G2CONF}
		--without-kde-applnk-path
		--enable-plugins=experimental
		--enable-image-inline
		--enable-canberra
		--enable-weather
		$(use_enable ssl nss)
		$(use_enable ssl smime)
		$(use_enable networkmanager nm)
		$(use_enable connman)
		$(use_enable gstreamer audio-inline)
		--disable-profiling
		--disable-pst-import
		$(use_enable python)
		pythonpath=$(PYTHON -2 -a)
		$(use_with clutter)
		$(use_with ldap openldap)
		$(use_with kerberos krb5 /usr)
		--disable-contacts-map
		--without-glade-catalog
		--disable-mono
		--disable-gtk3"

	# dang - I've changed this to do --enable-plugins=experimental.  This will
	# autodetect new-mail-notify and exchange, but that cannot be helped for the
	# moment.  They should be changed to depend on a --enable-<foo> like mono
	# is.  This cleans up a ton of crap from this ebuild.

	# Use NSS/NSPR only if 'ssl' is enabled.
	if use ssl ; then
		G2CONF="${G2CONF} --enable-nss=yes"
	else
		G2CONF="${G2CONF}
			--without-nspr-libs
			--without-nspr-includes
			--without-nss-libs
			--without-nss-includes"
	fi

	# NM and connman support cannot coexist
	if use networkmanager && use connman ; then
		ewarn "It is not possible to enable both ConnMan and NetworkManager, disabling connman..."
		G2CONF="${G2CONF} --disable-connman"
	fi

	epatch "${FILESDIR}"/${PN}-2.32.1-libnotify-0.7.patch

	# Fix invalid use of la file in contact-editor, upstream bug #635002
	epatch "${FILESDIR}/${PN}-2.32.0-wrong-lafile-usage.patch"

	# Fix compilation with --disable-smime, bug #356471
	epatch "${FILESDIR}/${PN}-2.32.2-smime-fix.patch"

	# Fix desktop file to work with latest glib
	epatch "${FILESDIR}/${PN}-2.32.2-mime-handler.patch"

	# Apply multiple backports from master fixing important bugs
	epatch "${WORKDIR}/${P}-patches"/*.patch

	# Fix build failure with glib-2.32, bug #412111
	epatch "${FILESDIR}/${P}-gmodule-explicit.patch"
	epatch "${FILESDIR}/${P}-g_thread_init.patch"

	# Support both old and new-buf libxml2 APIs, bug #459546
	epatch "${FILESDIR}/${P}-libxml2-2.9.patch"

	# Use NSS/NSPR only if 'ssl' is enabled.
	if use ssl ; then
		sed -e 's|mozilla-nss|nss|' \
			-e 's|mozilla-nspr|nspr|' \
			-i configure.ac configure || die "sed 2 failed"
	fi

	# Drop -Werror, bug #442242
	sed -i -e 's/-Werror //' configure.ac || die

	eautoreconf
	gnome2_src_prepare
}

pkg_postinst() {
	gnome2_pkg_postinst

	if ! has_version gnome-base/gnome-control-center; then
		elog "To change the default browser if you are not using GNOME, edit"
		elog "~/.local/share/applications/mimeapps.list so it includes the"
		elog "following content:"
		elog ""
		elog "[Default Applications]"
		elog "x-scheme-handler/http=firefox.desktop"
		elog "x-scheme-handler/https=firefox.desktop"
		elog ""
		elog "(replace firefox.desktop with the name of the appropriate .desktop"
		elog "file from /usr/share/applications if you use a different browser)."
		elog ""
		elog "Junk filters are now a run-time choice. You will get a choice of"
		elog "bogofilter or spamassassin based on which you have installed"
		elog ""
		elog "You have to install one of these for the spam filtering to actually work"
	fi
}
