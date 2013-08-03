# Distributed under the terms of the GNU General Public License v2

EAPI="5"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"

inherit eutils gnome2 virtualx

DESCRIPTION="Libraries for cryptographic UIs and accessing PKCS#11 modules"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2+ LGPL-2+"
SLOT="0/1" # subslot = suffix of libgcr-3
IUSE="debug +introspection"
KEYWORDS="~*"

COMMON_DEPEND="
	>=app-crypt/gnupg-2
	>=app-crypt/p11-kit-0.6
	>=dev-libs/glib-2.32:2
	>=dev-libs/libgcrypt-1.2.2:=
	>=dev-libs/libtasn1-1:=
	>=sys-apps/dbus-1.0
	>=x11-libs/gtk+-3.0:3
	introspection? ( >=dev-libs/gobject-introspection-1.29 )
"
RDEPEND="${COMMON_DEPEND}
	!<gnome-base/gnome-keyring-3.3
"
# gcr was part of gnome-keyring until 3.3
DEPEND="${COMMON_DEPEND}
	dev-libs/gobject-introspection-common
	dev-util/gdbus-codegen
	>=dev-util/gtk-doc-am-1.9
	>=dev-util/intltool-0.35
	sys-devel/gettext
	virtual/pkgconfig
"
# eautoreconf needs:
#	dev-libs/gobject-introspection-common

src_prepare() {
	DOCS="AUTHORS ChangeLog HACKING NEWS README"
	G2CONF="${G2CONF}
		$(use_enable introspection)
		$(usex debug --enable-debug=yes --enable-debug=default)
		--disable-update-icon-cache
		--disable-update-mime"

	epatch "${FILESDIR}/${P}-gobject.patch"
	
	# Disable stupid flag changes
	sed -e 's/CFLAGS="$CFLAGS -g"//' \
		-e 's/CFLAGS="$CFLAGS -O0"//' \
		-i configure.ac configure || die

	gnome2_src_prepare
}

src_test() {
	unset DBUS_SESSION_BUS_ADDRESS
	Xemake check
}
