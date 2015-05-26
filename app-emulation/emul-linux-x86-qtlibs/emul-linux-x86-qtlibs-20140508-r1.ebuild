# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils emul-linux-x86

LICENSE="LGPL-2.1 GPL-3"
KEYWORDS="-* amd64"

IUSE=""

DEPEND=""
RDEPEND="
	|| (
		~app-emulation/emul-linux-x86-baselibs-${PV}
		(
			>=dev-db/sqlite-3.8.2:3[abi_x86_32(-)]
			>=dev-libs/glib-2.34.3[abi_x86_32(-)]
			>=dev-libs/openssl-1.0.1h-r2[abi_x86_32(-)]
			>=media-libs/libpng-1.6.10:0/16[abi_x86_32(-)]
			>=media-libs/tiff-3.9.7-r1[abi_x86_32(-)]
			>=sys-apps/dbus-1.6.18-r1[abi_x86_32(-)]
			>=sys-libs/zlib-1.2.8-r1[abi_x86_32(-)]
			>=virtual/jpeg-62:62[abi_x86_32(-)]
		)
	)
	|| (
		~app-emulation/emul-linux-x86-medialibs-${PV}
		(
			>=media-libs/gstreamer-0.10.36-r2:0.10[abi_x86_32(-)]
			>=media-libs/gst-plugins-base-0.10.36:0.10[abi_x86_32(-)]
		)
	)
	|| (
		~app-emulation/emul-linux-x86-opengl-${PV}
		>=virtual/opengl-7.0-r1[abi_x86_32(-)]
	)
	|| (
		~app-emulation/emul-linux-x86-xlibs-${PV}
		(
			>=media-libs/fontconfig-2.10.92[abi_x86_32(-)]
			>=media-libs/freetype-2.5.0.1[abi_x86_32(-)]
			>=x11-libs/libICE-1.0.8-r1[abi_x86_32(-)]
			>=x11-libs/libSM-1.2.1-r1[abi_x86_32(-)]
			>=x11-libs/libX11-1.6.2[abi_x86_32(-)]
			>=x11-libs/libXcursor-1.1.14[abi_x86_32(-)]
			>=x11-libs/libXext-1.3.2[abi_x86_32(-)]
			>=x11-libs/libXfixes-5.0.1[abi_x86_32(-)]
			>=x11-libs/libXinerama-1.1.3[abi_x86_32(-)]
			>=x11-libs/libXi-1.7.2[abi_x86_32(-)]
			>=x11-libs/libXrandr-1.4.2[abi_x86_32(-)]
			>=x11-libs/libXrender-0.9.8[abi_x86_32(-)]
		)
	)"

src_install() {
	emul-linux-x86_src_install

	# Built against libmng-1 SONAME, remove this line once it's built against libmng-2 SONAME:
	rm "${D%/}"/usr/"$(get_abi_LIBDIR x86)"/qt4/plugins/imageformats/libqmng.so || die

	# Set LDPATH for not needing dev-qt/qtcore
	cat <<-EOF > "${T}/44qt4-emul"
	LDPATH=/usr/lib32/qt4
	EOF
	doenvd "${T}/44qt4-emul"
}
