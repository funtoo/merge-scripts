# Distributed under the terms of the GNU General Public License v2

EAPI="5"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
PYTHON_COMPAT=( python{2_6,2_7} )

inherit gnome2 python-r1

DESCRIPTION="The GNOME menu system, implementing the F.D.O cross-desktop spec"
HOMEPAGE="http://www.gnome.org"
SRC_URI="http://ftp.osuosl.org/pub/funtoo/distfiles/gnome-menus-3.6.2.tar.xz"
RESTRICT="mirror"

LICENSE="GPL-2+ LGPL-2+"
SLOT="3"
KEYWORDS="~*"

# +python for gmenu-simple-editor
IUSE="debug +introspection +python test"
REQUIRED_USE="
	python? (
		${PYTHON_REQUIRED_USE}
		introspection
	)
"

COMMON_DEPEND=">=dev-libs/glib-2.29.15:2
	introspection? ( >=dev-libs/gobject-introspection-0.9.5 )
	python? (
		${PYTHON_DEPS}
		dev-python/pygobject:3[${PYTHON_USEDEP}]
		x11-libs/gdk-pixbuf:2[introspection]
		x11-libs/gtk+:3[introspection] )"
# Older versions of slot 0 install the menu editor and the desktop directories
RDEPEND="${COMMON_DEPEND}
	!<gnome-base/gnome-menus-3.0.1-r1:0"
DEPEND="${COMMON_DEPEND}
	>=dev-util/intltool-0.40
	sys-devel/gettext
	virtual/pkgconfig
	test? ( dev-libs/gjs )"

src_prepare() {
	gnome2_src_prepare

	# Don't show KDE standalone settings desktop files in GNOME others menu
	epatch "${FILESDIR}/${PN}-3.0.0-ignore_kde_standalone.patch"

	if use python; then
		python_copy_sources
	else
		sed -e 's/\(SUBDIRS.*\) simple-editor/\1/' \
			-i Makefile.* || die "sed failed"
	fi
}

src_configure() {
	DOCS="AUTHORS ChangeLog HACKING NEWS README"

	# Do NOT compile with --disable-debug/--enable-debug=no
	# It disables api usage checks
	G2CONF="${G2CONF}
		$(usex debug --enable-debug=yes --enable-debug=minimum)
		$(use_enable introspection)
		--disable-static"

	if use python; then
		python_foreach_impl run_in_build_dir gnome2_src_configure
	else
		gnome2_src_configure
	fi
}

src_compile() {
	if use python; then
		python_foreach_impl run_in_build_dir gnome2_src_compile
	else
		gnome2_src_compile
	fi
}

src_test() {
	if use python; then
		python_foreach_impl run_in_build_dir default
	else
		default
	fi
}

src_install() {
	if use python; then
		installing() {
			gnome2_src_install
			# Massage shebang to make python_doscript happy
			sed -e 's:#!'"${PYTHON}:#!/usr/bin/python:" \
				-i simple-editor/gmenu-simple-editor || die
				python_doscript simple-editor/gmenu-simple-editor
			}
		python_foreach_impl run_in_build_dir installing
	else
		gnome2_src_install
	fi

	# Prefix menu, bug #256614
	mv "${ED}"/etc/xdg/menus/applications.menu \
		"${ED}"/etc/xdg/menus/gnome-applications.menu || die "menu move failed"

	exeinto /etc/X11/xinit/xinitrc.d/
	newexe "${FILESDIR}/10-xdg-menu-gnome-r1" 10-xdg-menu-gnome
}

run_in_build_dir() {
	pushd "${BUILD_DIR}" > /dev/null || die
	"$@"
	popd > /dev/null
}
