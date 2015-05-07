# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils toolchain-funcs

DESCRIPTION="a generic, highly customizable, and efficient menu for the X Window System"
HOMEPAGE="https://bitbucket.org/solitarycipher/dmenu2/"
SRC_URI="https://bitbucket.org/solitarycipher/dmenu2/downloads/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="*"
IUSE="xinerama"

RDEPEND="
	x11-libs/libX11
	x11-libs/libXft
	xinerama? ( x11-libs/libXinerama )
"
DEPEND="${RDEPEND}
	xinerama? ( virtual/pkgconfig )
"

src_prepare() {
	# Respect our flags
	sed -i \
		-e '/^CFLAGS/{s|=.*|+= -std=c99 $(INCS) $(CPPFLAGS)|}' \
		-e '/^LDFLAGS/s|= -s|+=|' \
		config.mk || die
	# Make make verbose
	sed -i \
		-e 's|^	@|	|g' \
		-e '/^	echo/d' \
		Makefile || die
	#use xft && epatch "${FILESDIR}"/${PN}-4.5-xft-3.patch
	epatch_user
}

src_compile() {
	emake CC=$(tc-getCC) \
		"XFTINC=$( $(tc-getPKG_CONFIG) --cflags xft 2>/dev/null )" \
		"XFTLIBS=$( $(tc-getPKG_CONFIG) --libs xft 2>/dev/null )" \
		"XINERAMAFLAGS=$(
			usex xinerama "-DXINERAMA $(
				$(tc-getPKG_CONFIG) --cflags xinerama 2>/dev/null
			)" ''
		)" \
		"XINERAMALIBS=$(
			usex xinerama "$( $(tc-getPKG_CONFIG) --libs xinerama 2>/dev/null)" ''
		)"
}

src_install() {
	emake DESTDIR="${D}" PREFIX="/usr" install
}

pkg_postinst() {
	ewarn "dmenu2 providing same binaries as dmenu"
	ewarn "both packages cannot co-exist, please, remove either one"
}