# Distributed under the terms of the GNU General Public License v2

EAPI=1

inherit eutils autotools

DESCRIPTION="Ice Window Manager with Themes"

HOMEPAGE="http://www.icewm.org/"

#fix for icewm preversion package names
S=${WORKDIR}/${P/_}

SRC_URI="mirror://sourceforge/${PN}/${P/_}.tar.gz"

LICENSE="GPL-2"
SLOT="0"

KEYWORDS="*"

IUSE="gnome imlib nls truetype xinerama minimal debug uclibc"

RDEPEND="x11-libs/libX11
	x11-libs/libXrandr
	x11-libs/libXext
	x11-libs/libXpm
	x11-libs/libXrender
	x11-libs/libXft
	x11-libs/libSM
	x11-libs/libICE
	xinerama? ( x11-libs/libXinerama )
	gnome? ( gnome-base/gnome-desktop:2
		gnome-base/libgnomeui )
	imlib? ( >=media-libs/imlib-1.9.10-r1 )
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

src_unpack() {
	unpack ${A}
	cd "${S}/src"

	use uclibc && epatch "${FILESDIR}/icewm-uclibc.patch"

	echo "#!/bin/sh" > "$T/icewm"
	echo "/usr/bin/icewm-session" >> "$T/icewm"

	cd "${S}"
	#Fixing gnome2 support
	epatch "${FILESDIR}/${P}-gnome2.patch"
	# build fix for libX11-1.5.0, bug 420773
	epatch "${FILESDIR}"/${PN}-1.2.37-libX11-1.5.0-deprecated.patch

	eautoreconf
}

src_compile() {

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
		--without-esd-config
		$(use_enable gnome menus-gnome2)
		$(use_enable nls)
		$(use_enable nls i18n)
		$(use_with imlib)
		$(use_enable x86 x86-asm)
		$(use_enable xinerama)
		$(use_enable debug)"

	CXXFLAGS="${CXXFLAGS}" econf ${myconf} || die "configure failed"

	sed -i "s:/icewm-\$(VERSION)::" src/Makefile || die "patch failed"
	sed -i "s:ungif:gif:" src/Makefile || die "libungif fix failed"

	emake || die "emake failed"
}

src_install(){
	emake DESTDIR="${D}" install || die "make install failed"

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
