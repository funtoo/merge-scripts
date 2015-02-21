# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit cmake-utils eutils gnome2-utils subversion

MY_P="${PN}-${PV/_/-}"

DESCRIPTION="A lightweight panel/taskbar"
HOMEPAGE="http://code.google.com/p/tint2"
ESVN_REPO_URI="http://tint2.googlecode.com/svn/trunk"
ESVN_REVISION="725"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~*"
IUSE="battery examples tint2conf startup-notification svg"

PDEPEND="tint2conf? ( x11-misc/tintwizard )"

RDEPEND="startup-notification? ( x11-libs/startup-notification )
	svg? ( gnome-base/librsvg )
	dev-libs/glib:2
	media-libs/imlib2[X]
	x11-libs/cairo
	x11-libs/libX11
	x11-libs/libXinerama
	x11-libs/libXdamage
	x11-libs/libXcomposite
	x11-libs/libXrender
	x11-libs/libXrandr
	x11-libs/pango[X]"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	x11-proto/xineramaproto"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	use tint2conf && epatch "${FILESDIR}/${PN}-icon-cache.patch"
}

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use_enable battery BATTERY)
		$(cmake-utils_use_enable examples EXAMPLES)
		$(cmake-utils_use_enable tint2conf TINT2CONF)
		$(cmake-utils_use_enable startup-notification SN)
		$(cmake-utils_use_enable svg RSVG)

		"-DDOCDIR=/usr/share/doc/${PF}"
	)

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	if use tint2conf ; then
		rm "${D}/usr/bin/tintwizard.py" || die

		gnome2_icon_cache_update
	fi
}
