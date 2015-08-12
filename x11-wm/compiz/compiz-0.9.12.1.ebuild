# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit cmake-utils eutils gnome2-utils toolchain-funcs python versionator
SRC_URI="https://launchpad.net/${PN}/$(get_version_component_range 1-3)/${PV}/+download/${P}.tar.bz2"
KEYWORDS="*"
DESCRIPTION="OpenGL window and compositing manager"
HOMEPAGE="http://www.compiz.org/"

PATCHSET_URI="https://github.com/megabaks/stuff/blob/master/x11-wm/compiz/files/compiz-kde-4.8.patch"

LICENSE="GPL-2 LGPL-2.1 MIT"
SLOT="0"

IUSE="+cairo debug dbus fuse gnome gtk kde +svg test"

COMMONDEPEND="
		dev-libs/boost
		dev-libs/glib:2
		dev-cpp/glibmm
		dev-libs/libxml2
		dev-libs/libxslt
		dev-python/pyrex
		dev-libs/protobuf
		media-libs/libpng
		x11-base/xorg-server
		x11-libs/libX11
		x11-libs/libXcomposite
		x11-libs/libXdamage
		x11-libs/libXext
		x11-libs/libXrandr
		x11-libs/libXrender
		x11-libs/libXinerama
		x11-libs/libICE
		x11-libs/libSM
		x11-libs/startup-notification
		virtual/opengl
		virtual/glu
		cairo? ( x11-libs/cairo[X] )
		fuse? ( sys-fs/fuse )
		gtk? (
				>=x11-libs/gtk+-2.18.0
				>=x11-libs/libwnck-2.19.4
				x11-libs/pango
				gnome? (
						gnome-base/gnome-desktop
						gnome-base/gconf
						x11-wm/metacity
				)
		)
		kde? ( kde-base/kwin:4 )
		svg? (
				gnome-base/librsvg:2
				x11-libs/cairo
		)
		dbus? ( sys-apps/dbus )"

DEPEND="${COMMONDEPEND}
		app-admin/chrpath
		virtual/pkgconfig
		x11-proto/damageproto
		x11-proto/xineramaproto
		test? (
				dev-cpp/gtest
				dev-cpp/gmock 
		)"

RDEPEND="${COMMONDEPEND}
		dev-python/pygtk
		x11-apps/mesa-progs
		x11-apps/xvinfo
		x11-themes/hicolor-icon-theme"

# TODO:
# - Remove automagic dependency for coverage report generation tools
# - Fix Xig-0 automagic resolving('CMake Warning at tests/integration/xig/CMakeLists.txt:30 (message): Xig not found, you will not be able to run X Server integration tests')
# - Check proper compilation with missing gettext/intltool
# - CFLAGS are NOT respected, this needs to be fixed
# - Default decorator exec command in ccsm is bad
# - Check all dependencies once more
# - Check CMakeFiles.txt this subdirectories :
# cmake - ?
# src
# compizconfig
# plugins
# tests - ?

pkg_pretend() {
	if [[ ${MERGE_TYPE} != binary ]]; then
		[[ $(gcc-major-version) -lt 4 ]] || \
		(	[[ $(gcc-major-version) -eq 4 && $(gcc-minor-version) -lt 6 ]] ) \
		&& die "Sorry, but GCC version 4.6 or greater is required to continue."
	fi
}

#src_unpack() {
#git-2_src_unpack
#}

#src_unpack() {
#}
src_prepare() {

#epatch "${FILESDIR}/fix_access_violation.patch"

	echo "gtk/gnome/compiz-wm.desktop.in" >> "${S}/po/POTFILES.skip"
	echo "metadata/core.xml.in" >> "${S}/po/POTFILES.skip"

# Fix wrong path for icons
	sed -i 's:DataDir = "@prefix@/share":DataDir = "/usr/share":' compizconfig/ccsm/ccm/Constants.py.in
}

pkg_setup() {
	python_set_active_version 2
}

src_configure() {
	BUILD_DIR=${WORKDIR}/build
	local mycmakeargs=(
		"$(cmake-utils_use_use gnome GCONF)"
		"$(cmake-utils_use_use gnome GNOME)"
		"$(cmake-utils_use_use gnome GSETTINGS)"
		"$(cmake-utils_use_use gtk GTK)"
		"$(cmake-utils_use_use kde KDE4)"
		"$(cmake-utils_use test COMPIZ_BUILD_TESTING)"
		"-DCMAKE_INSTALL_PREFIX=/usr"
		"-DCMAKE_C_FLAGS=$(usex debug '-DDEBUG -ggdb' '')"
		"-DCMAKE_CXX_FLAGS=$(usex debug '-DDEBUG -ggdb' '')"
		"-DCOMPIZ_DEFAULT_PLUGINS=ccp"
		"-DCOMPIZ_DISABLE_SCHEMAS_INSTALL=ON"
		"-DCOMPIZ_PACKAGING_ENABLED=ON"
		"-HAVE_WNCK_WINDOW_HAS_NAME=1"
		"-Wno-dev=ON")

	cmake-utils_src_configure
}

src_install() {
	pushd "${CMAKE_BUILD_DIR}"

	# Fix paths to avoid sandbox access violation
	# 'emake DESTDIR=${D} install' does not work with compiz cmake files!

	for i in `find . -type f -name "cmake_install.cmake"` ; do
		sed -e "s|/usr|${D}/usr|g" -i "${i}"  || die "sed failed"
	done

	emake install
	popd
}

pkg_preinst() {
	use gnome && gnome2_gconf_savelist
}

pkg_postinst() {
	use gnome && gnome2_gconf_install

	if use dbus; then
		ewarn "The dbus plugin is known to crash compiz in this version. Disable"
		ewarn "it if you experience crashes when plugins are enabled/disabled."
	fi
}

pkg_prerm() {
	use gnome && gnome2_gconf_uninstall
}
