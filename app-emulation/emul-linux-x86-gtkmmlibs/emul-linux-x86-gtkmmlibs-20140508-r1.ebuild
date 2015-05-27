# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit emul-linux-x86

LICENSE="LGPL-2 LGPL-2.1 GPL-2"
KEYWORDS="-* ~amd64"

IUSE="abi_x86_32"

DEPEND=""
RDEPEND="~app-emulation/emul-linux-x86-baselibs-${PV}
	~app-emulation/emul-linux-x86-cpplibs-${PV}
	~app-emulation/emul-linux-x86-gtklibs-${PV}
	!abi_x86_32? (
		!>=dev-cpp/glibmm-2.42.0-r1:2[abi_x86_32(-)]
		!>=dev-cpp/cairomm-1.10.0-r1[abi_x86_32(-)]
		!>=dev-cpp/atkmm-2.22.7-r1[abi_x86_32(-)]
		!>=dev-cpp/pangomm-2.34.0-r1:1.4[abi_x86_32(-)]
		!>=dev-cpp/gtkmm-2.24.4-r1:2.4[abi_x86_32(-)]
		!>=dev-cpp/libglademm-2.6.7-r1:2.4[abi_x86_32(-)]
	)
	abi_x86_32? (
		>=dev-cpp/glibmm-2.42.0-r1:2[abi_x86_32(-)]
		>=dev-cpp/cairomm-1.10.0-r1[abi_x86_32(-)]
		>=dev-cpp/atkmm-2.22.7-r1[abi_x86_32(-)]
		>=dev-cpp/pangomm-2.34.0-r1:1.4[abi_x86_32(-)]
		>=dev-cpp/gtkmm-2.24.4-r1:2.4[abi_x86_32(-)]
		>=dev-cpp/libglademm-2.6.7-r1:2.4[abi_x86_32(-)]
	)"

src_prepare() {
	emul-linux-x86_src_prepare

	# Remove migrated stuff.
	use abi_x86_32 && rm -f $(cat "${FILESDIR}/remove-native-${PVR}")
}

src_install() {
	# Don't die if all files were migrated
	if ! use abi_x86_32 || [[ $(find "${S}" . -type f | wc -l) != "0" ]]; then
		emul-linux-x86_src_install
	fi
}
