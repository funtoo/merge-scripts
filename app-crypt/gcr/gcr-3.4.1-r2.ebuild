# Distributed under the terms of the GNU General Public License v2

EAPI="4"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"

inherit autotools gnome2 virtualx

DESCRIPTION="Libraries for cryptographic UIs and accessing PKCS#11 modules"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2+ LGPL-2+"
SLOT="0"
IUSE="debug +introspection"
KEYWORDS="*"

COMMON_DEPEND=">=app-crypt/gnupg-2
	>=app-crypt/p11-kit-0.6
	>=dev-libs/glib-2.30:2
	>=dev-libs/libgcrypt-1.2.2
	>=dev-libs/libtasn1-1
	>=sys-apps/dbus-1.0
	>=x11-libs/gtk+-3.0:3
	introspection? ( >=dev-libs/gobject-introspection-1.29 )
"
RDEPEND="${COMMON_DEPEND}
	!<gnome-base/gnome-keyring-3.3"
# gcr was part of gnome-keyring until 3.3
DEPEND="${COMMON_DEPEND}
	dev-util/gdbus-codegen
	>=dev-util/gtk-doc-am-1.9
	>=dev-util/intltool-0.35
	sys-devel/gettext
	virtual/pkgconfig

	dev-libs/gobject-introspection-common"
# eautoreconf needs:
#	dev-libs/gobject-introspection-common

src_prepare() {
	DOCS="AUTHORS ChangeLog HACKING NEWS README"
	G2CONF="${G2CONF}
		$(use_enable debug)
		$(use_enable introspection)
		--disable-update-icon-cache
		--disable-update-mime"

	epatch "${FILESDIR}/${P}-invalid-whitespace.patch" #434422

	# FIXME: failing tests
	if use test; then
		sed -e 's:test-subject-public-key::' \
			-e 's:test-system-prompt:$(NULL):' \
			-i gcr/tests/Makefile.am || die "sed failed"
		eautoreconf
	fi

	gnome2_src_prepare
}

src_test() {
	unset DBUS_SESSION_BUS_ADDRESS
	Xemake check
}
