# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit autotools flag-o-matic eutils

THEMES_RELEASE=0.5.2
MY_P=emerald
MY_P_VER=0.9.5

DESCRIPTION="Emerald Window Decorator"
HOMEPAGE="http://www.compiz.org/"
SRC_URI="https://launchpad.net/~nilarimogard/+archive/ubuntu/webupd8/+files/${MY_P}_${MY_P_VER}.orig.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

PDEPEND="~x11-themes/emerald-themes-${THEMES_RELEASE}"

RDEPEND="
	>=x11-libs/gtk+-2.8.0:2
	>=x11-libs/libwnck-2.31.0
	>=x11-wm/compiz-${PV}
"

DEPEND="${RDEPEND}
	>=dev-util/intltool-0.35
	virtual/pkgconfig
	>=sys-devel/gettext-0.15
"

src_prepare() {
	intltoolize --automake --copy --force || die
	eautoreconf || die "eautoreconf failed"
	#Secure linking needed
	append-ldflags -Wl,-lm,-ldl
	epatch_user
}

src_configure() {
	econf --disable-mime-update || die "econf failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
}
