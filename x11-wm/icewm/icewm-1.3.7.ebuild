# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit eutils

DESCRIPTION="Ice Window Manager with Themes"
HOMEPAGE="http://www.icewm.org/"
LICENSE="GPL-2"
SRC_URI="mirror://sourceforge/${PN}/${P/_}.tar.gz"
SLOT="0"
KEYWORDS="~*"
IUSE="debug gnome minimal nls truetype uclibc xinerama"

#fix for icewm preversion package names
S=${WORKDIR}/${P/_}

RDEPEND="x11-libs/libX11
	x11-libs/libXrandr
	x11-libs/libXext
	x11-libs/libXpm
	x11-libs/libXrender
	x11-libs/libXft
	x11-libs/libSM
	x11-libs/libICE
	xinerama? ( x11-libs/libXinerama )
	gnome? ( gnome-base/gnome-desktop:2 gnome-base/libgnomeui )
	nls? ( sys-devel/gettext )
	truetype? ( >=media-libs/freetype-2.0.9 )
	media-libs/giflib"

DEPEND="${RDEPEND}
	x11-proto/xproto
	x11-proto/xextproto
	xinerama? ( x11-proto/xineramaproto )
	>=sys-apps/sed-4"

pkg_setup() {
	if use truetype && use minimal; then
		ewarn "You have both 'truetype' and 'minimal' use flags enabled."
		ewarn "If you really want a minimal install, you will have to turn off"
		ewarn "the truetype flag for this package."
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-gcc44.patch \
		"${FILESDIR}"/${P}-gcc47.patch
	cd "${S}/src"
	use uclibc && epatch "${FILESDIR}/${PN}-uclibc.patch"
	# build fix for libX11-1.5.0, bug 420773
	epatch "${FILESDIR}"/${PN}-1.2.37-libX11-1.5.0-deprecated.patch

	echo "#!/bin/sh" > "$T/${PN}"
	echo "/usr/bin/icewm-session" >> "$T/${PN}"
}

src_configure() {
	if use truetype
	then
		myconf="${myconf} --enable-gradients --enable-shape --enable-shaped-decorations"
	else
		myconf="${myconf} --disable-xfreetype --enable-corefonts
			$(use_enable minimal lite)"
	fi

	myconf="${myconf}
		--with-libdir=/usr/share/icewm
		--with-cfgdir=/etc/icewm
		--with-docdir=/usr/share/doc/${PF}/html
		$(use_enable debug)
		$(use_enable gnome menus-gnome2)
		$(use_enable nls i18n)
		$(use_enable nls)
		$(use_enable x86 x86-asm)
		$(use_enable xinerama)
		--without-esd-config"

	CXXFLAGS="${CXXFLAGS}" econf ${myconf}

	sed -i "s:/icewm-\$(VERSION)::" src/Makefile || die "patch failed"
	sed -i "s:ungif:gif:" src/Makefile || die "libungif fix failed"
}

src_install(){
	default

	dodoc AUTHORS BUGS CHANGES PLATFORMS README* TODO VERSION
	dohtml -a html,sgml doc/*

	exeinto /etc/X11/Sessions
	doexe "$T/icewm"

	insinto /usr/share/xsessions
	doins "${FILESDIR}/IceWM.desktop"
}

pkg_postinst() {
	if use gnome; then
		elog "You have enabled gnome USE flag which provides icewm-menu-gnome2 ."
		elog "It is used internally and generates IceWM program menus from"
		elog "FreeDesktop .desktop files"
	fi
}
