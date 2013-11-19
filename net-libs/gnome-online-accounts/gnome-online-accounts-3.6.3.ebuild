# Distributed under the terms of the GNU General Public License v2

EAPI="5"
GNOME2_LA_PUNT="yes"

inherit eutils gnome2

DESCRIPTION="GNOME framework for accessing online accounts"
HOMEPAGE="https://live.gnome.org/GnomeOnlineAccounts"

LICENSE="LGPL-2+"
SLOT="0"
IUSE="gnome +introspection kerberos"
KEYWORDS="~*"

# pango used in goaeditablelabel
# libsoup used in goaoauthprovider
# goa kerberos provider is incompatible with app-crypt/heimdal, see
# https://bugzilla.gnome.org/show_bug.cgi?id=692250
RDEPEND="
	>=dev-libs/glib-2.32:2
	app-crypt/libsecret
	dev-libs/json-glib
	dev-libs/libxml2:2
	net-libs/libsoup:2.4
	>=net-libs/libsoup-gnome-2.38:2.4
	net-libs/rest:0.7
	net-libs/webkit-gtk:3
	>=x11-libs/gtk+-3.5.1:3
	>=x11-libs/libnotify-0.7:=
	x11-libs/pango

	introspection? ( >=dev-libs/gobject-introspection-0.6.2 )
	kerberos? (
		app-crypt/gcr
		app-crypt/mit-krb5 )
"
# goa-daemon can launch gnome-control-center
PDEPEND="gnome? ( >=gnome-base/gnome-control-center-3.2[gnome-online-accounts(+)] )"
DEPEND="${RDEPEND}
	dev-libs/libxslt
	>=dev-util/gtk-doc-am-1.3
	>=dev-util/gdbus-codegen-2.30.0
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig
"

src_prepare() {
	# fix build failure with gcc-4.5 and USE=kerberos, bug #450706
	# https://bugzilla.gnome.org/show_bug.cgi?id=692251
	epatch "${FILESDIR}/${PN}-3.6.2-GoaKerberosIdentity.patch"
	gnome2_src_prepare
}

src_configure() {
	# TODO: Give users a way to set the G/Y!/FB/Twitter/Windows Live secrets
	gnome2_src_configure \
		--disable-static \
		--enable-documentation \
		--enable-exchange \
		--enable-facebook \
		--enable-windows-live \
		$(use_enable kerberos)
}
