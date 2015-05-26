# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit emul-linux-x86

SRC_URI="!abi_x86_32? ( ${SRC_URI} )"
LICENSE="!abi_x86_32? ( BSD MIT LGPL-3 SGI-B-2.0 ) abi_x86_32? ( metapackage )"
KEYWORDS="-* amd64 ~amd64-linux"
IUSE="abi_x86_32"

DEPEND="app-eselect/eselect-opengl
	>=app-eselect/eselect-mesa-0.0.9"
RDEPEND=">=app-emulation/emul-linux-x86-xlibs-20100611
	!<app-emulation/emul-linux-x86-xlibs-20100611
	media-libs/mesa

	!abi_x86_32? (
		!media-libs/freeglut[abi_x86_32(-)]
		!media-libs/glew[abi_x86_32(-)]
		!media-libs/glu[abi_x86_32(-)]
		!media-libs/mesa[abi_x86_32(-)]
	)
	abi_x86_32? (
		>=media-libs/freeglut-2.8.1[abi_x86_32(-)]
		>=media-libs/glew-1.10.0-r1[abi_x86_32(-)]
		>=media-libs/glu-9.0.0-r1[abi_x86_32(-)]
		>=media-libs/mesa-9.1.6[abi_x86_32(-)]
	)"

src_prepare() {
	use abi_x86_32 && return
	emul-linux-x86_src_prepare
	rm -f "${S}/usr/lib32/libGL.so" || die
	rm -f "${S}/usr/lib32/libGL.so.1" || die
}

src_install() {
	use abi_x86_32 || emul-linux-x86_src_install
}

pkg_postinst() {
	use abi_x86_32 && return
	# Update GL symlinks
	eselect opengl set --use-old || die
	# And the same for mesa (bug #355393)
	eselect mesa set 32bit --auto || die
}
