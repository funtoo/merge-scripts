# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit eutils versionator flag-o-matic multilib

DESCRIPTION="GTK+ version of wxWidgets, a cross-platform C++ GUI toolkit"
HOMEPAGE="http://wxwidgets.org/"

BASE_PV="$(get_version_component_range 1-3)"
BASE_P="${PN}-${BASE_PV}"

# we use the wxPython tarballs because they include the full wxGTK sources and
# docs, and are released more frequently than wxGTK.
SRC_URI="mirror://sourceforge/wxpython/wxPython-src-${PV}.tar.bz2"

KEYWORDS="*"
IUSE="X aqua doc debug gnome gstreamer odbc opengl pch sdl tiff"

RDEPEND="
	dev-libs/expat
	odbc?   ( dev-db/unixODBC )
	sdl?    ( media-libs/libsdl )
	X?  (
		dev-libs/glib:2
		media-libs/libpng:0
		sys-libs/zlib
		virtual/jpeg
		x11-libs/gtk+:2
		x11-libs/libSM
		x11-libs/libXinerama
		x11-libs/libXxf86vm
		x11-libs/pango[X]
		gnome?  ( gnome-base/libgnomeprintui:2.2 )
		gstreamer? (
			gnome-base/gconf:2
			media-libs/gstreamer:0.10
			media-libs/gst-plugins-base:0.10 )
		opengl? ( virtual/opengl )
		tiff?   ( media-libs/tiff:0 )
		)
	aqua? (
		>=x11-libs/gtk+-2.4[aqua=]
		virtual/jpeg
		tiff?   ( media-libs/tiff:0 )
		)"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	opengl? ( virtual/glu )
	X?  (
		x11-proto/xproto
		x11-proto/xineramaproto
		x11-proto/xf86vidmodeproto
		)
	>=app-admin/eselect-wxwidgets-0.7"

SLOT="2.8"
LICENSE="wxWinLL-3
		GPL-2
		odbc?	( LGPL-2 )
		doc?	( wxWinFDL-3 )"

S="${WORKDIR}/wxPython-src-${PV}"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.8.11-unicode-odbc.patch
	epatch "${FILESDIR}"/${PN}-2.8.11-collision.patch
	epatch "${FILESDIR}"/${PN}-2.8.7-mmedia.patch              # Bug #174874
	epatch "${FILESDIR}"/${PN}-2.8.10.1-odbc-defines.patch     # Bug #310923
	sed \
		-e "s:/usr:${EPREFIX}/usr:g" \
		-e '/SEARCH_INCLUDE="\\/,/"/cSEARCH_INCLUDE="'${EPREFIX}'/usr/include"' \
		-i configure || die "sed on configure failed"
}

src_configure() {
	local myconf

	append-flags -fno-strict-aliasing

	# X independent options
	myconf="--enable-compat26
			--enable-shared
			--enable-unicode
			--with-regex=builtin
			--with-zlib=sys
			--with-expat=sys
			$(use_enable debug)
			$(use_enable pch precomp-headers)
			$(use_with odbc odbc sys)
			$(use_with sdl)
			$(use_with tiff libtiff sys)"

	# wxGTK options
	#   --enable-graphics_ctx - needed for webkit, editra
	#   --without-gnomevfs - bug #203389

	use X && \
		myconf="${myconf}
			--enable-graphics_ctx
			--enable-gui
			--with-libpng=sys
			--with-libxpm=sys
			--with-libjpeg=sys
			$(use_enable gstreamer mediactrl)
			$(use_enable opengl)
			$(use_with opengl)
			$(use_with gnome gnomeprint)
			--without-gnomevfs"

	use aqua && \
		myconf="${myconf}
			--enable-graphics_ctx
			--enable-gui
			--with-libpng=sys
			--with-libxpm=sys
			--with-libjpeg=sys
			--with-mac
			--with-opengl"
			# cocoa toolkit seems to be broken
	# wxBase options
	if use !X && use !aqua ; then
		myconf="${myconf}
			--disable-gui"
	fi

	mkdir "${S}"/wxgtk_build
	cd "${S}"/wxgtk_build

	ECONF_SOURCE="${S}" econf ${myconf}
}

src_compile() {
	cd "${S}"/wxgtk_build

	emake

	if [[ -d contrib/src ]]; then
		cd contrib/src
		emake
	fi
}

src_install() {
	cd "${S}"/wxgtk_build

	emake DESTDIR="${D}" install

	if [[ -d contrib/src ]]; then
		cd contrib/src
		emake DESTDIR="${D}" install
	fi

	cd "${S}"/docs
	dodoc changes.txt readme.txt todo30.txt
	newdoc base/readme.txt base_readme.txt
	newdoc gtk/readme.txt gtk_readme.txt

	if use doc; then
		dohtml -r "${S}"/docs/html/*
	fi

	# We don't want this
	local wxmsw="${ED}usr/share/locale/it/LC_MESSAGES/wxmsw.mo"
	[[ -e ${wxmsw} ]] && rm "${wxmsw}"
}

pkg_postinst() {
	has_version app-admin/eselect-wxwidgets \
		&& eselect wxwidgets update

	if [[ -e "${ROOT}"/usr/lib/wx/config ]] ; then
		local wxwidgets=( $(find -H "${ROOT}"/usr/lib/wx/config/* -printf "%f " 2> /dev/null) )
		if [[ ! -z "${wxwidgets[@]}" && "${#wxwidgets[@]}" == 1 ]] ; then
			eselect wxwidgets set  "${wxwidgets[0]}"
			echo
			elog "Portage detected that your system has only one wxWidgets profile."
			elog "Your systems wxWidgets profile is now set to ${wxwidgets[0]}"
			echo
		fi
	fi
}

pkg_postrm() {
	has_version app-admin/eselect-wxwidgets \
		&& eselect wxwidgets update
}
