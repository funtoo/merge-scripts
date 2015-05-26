# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit emul-linux-x86

LICENSE="!abi_x86_32? ( LGPL-2 LGPL-2.1 ZLIB ) abi_x86_32? ( metapackage )"
KEYWORDS="-* amd64"
IUSE="abi_x86_32"

DEPEND=""
RDEPEND="
	!abi_x86_32? (
		~app-emulation/emul-linux-x86-xlibs-${PV}
		~app-emulation/emul-linux-x86-baselibs-${PV}
		~app-emulation/emul-linux-x86-soundlibs-${PV}
		~app-emulation/emul-linux-x86-medialibs-${PV}
	)
	abi_x86_32? (
		>=media-libs/openal-1.15.1-r1[abi_x86_32(-)]
		>=media-libs/freealut-1.1.0-r3[abi_x86_32(-)]
		>=media-libs/libsdl-1.2.15-r5[abi_x86_32(-)]
		>=media-libs/sdl-gfx-2.0.24-r3[abi_x86_32(-)]
		>=media-libs/sdl-image-1.2.12-r1[abi_x86_32(-)]
		>=media-libs/sdl-mixer-1.2.12-r4[abi_x86_32(-)]
		>=media-libs/sdl-net-1.2.8-r1[abi_x86_32(-)]
		>=media-libs/sdl-sound-1.0.3-r1[abi_x86_32(-)]
		>=media-libs/sdl-ttf-2.0.11-r1[abi_x86_32(-)]
		>=media-libs/smpeg-0.4.4-r10[abi_x86_32(-)]
	)"

src_prepare() {
	use abi_x86_32 || emul-linux-x86_src_prepare
}

src_install() {
	use abi_x86_32 || emul-linux-x86_src_install
}
