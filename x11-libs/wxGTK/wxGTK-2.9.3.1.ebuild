# Distributed under the terms of the GNU General Public License v2

EAPI="3"

inherit eutils flag-o-matic

DESCRIPTION="GTK+ version of wxWidgets, a cross-platform C++ GUI toolkit"
HOMEPAGE="http://wxwidgets.org/"

# we use the wxPython tarballs because they include the full wxGTK sources and
# docs, and are released more frequently than wxGTK.
SRC_URI="mirror://sourceforge/wxpython/wxPython-src-${PV}.tar.bz2
	doc? ( mirror://sourceforge/wxpython/wxPython-docs-${PV}.tar.bz2 )"

KEYWORDS="~*"
IUSE="X aqua doc debug gnome gstreamer opengl pch sdl tiff webkit"

RDEPEND="
	dev-libs/expat
	sdl?    ( media-libs/libsdl )
	X?  (
		>=dev-libs/glib-2.22:2
		media-libs/libpng:0
		sys-libs/zlib
		virtual/jpeg
		>=x11-libs/gtk+-2.18:2
		x11-libs/libSM
		x11-libs/libXinerama
		x11-libs/libXxf86vm
		x11-libs/pango[X]
		gnome? ( gnome-base/libgnomeprintui:2.2 )
		gstreamer? (
			gnome-base/gconf:2
			media-libs/gstreamer:0.10
			media-libs/gst-plugins-base:0.10 )
		opengl? ( virtual/opengl )
		tiff?   ( media-libs/tiff:0 )
		webkit? ( net-libs/webkit-gtk:2 )
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
	>=app-admin/eselect-wxwidgets-1.4"
#	test? ( dev-util/cppunit )

SLOT="2.9"
LICENSE="wxWinLL-3
		GPL-2
		doc?	( wxWinFDL-3 )"

S="${WORKDIR}/wxPython-src-${PV}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-collision.patch
}

src_configure() {
	local myconf

	append-flags -fno-strict-aliasing

	# X independent options
	myconf="--enable-compat26
			--with-zlib=sys
			--with-expat=sys
			$(use_enable pch precomp-headers)
			$(use_with sdl)"

	# debug in >=2.9
	#   if USE="debug" set max debug level (wxDEBUG_LEVEL=2)
	#   if USE="-debug" use the default (wxDEBUG_LEVEL=1)
	#   do not use --disable-debug
	# this means we always build debugging features into the library, and
	# apps can disable these features by building w/ -NDEBUG or wxDEBUG_LEVEL_0.
	# wxDEBUG_LEVEL=2 enables assertions that have expensive runtime costs.
	# http://docs.wxwidgets.org/2.9/overview_debugging.html
	# http://groups.google.com/group/wx-dev/browse_thread/thread/c3c7e78d63d7777f/05dee25410052d9c
	use debug \
		&& myconf="${myconf} --enable-debug=max"

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
			--without-gnomevfs
			$(use_enable gstreamer mediactrl)
			$(use_enable webkit webview)
			$(use_with opengl)
			$(use_with gnome gnomeprint)
			$(use_with !gnome gtkprint)
			$(use_with tiff libtiff sys)"

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
	emake || die "make failed."
}

# Currently fails - need to investigate
#src_test() {
#	cd "${S}"/wxgtk_build/tests
#	emake || die "failed building testsuite"
#	./test -d || ewarn "failed running testsuite"
#}

src_install() {
	cd "${S}"/wxgtk_build

	emake DESTDIR="${D}" install || die "install failed."

	cd "${S}"/docs
	dodoc changes.txt readme.txt
	newdoc base/readme.txt base_readme.txt
	newdoc gtk/readme.txt gtk_readme.txt

	if use doc; then
		dohtml -r "${S}"/docs/doxygen/out/html/*
	fi
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
