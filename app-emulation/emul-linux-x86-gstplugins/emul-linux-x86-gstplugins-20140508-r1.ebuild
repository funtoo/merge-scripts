# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit emul-linux-x86

LICENSE="!abi_x86_32? ( GPL-2 LGPL-2 LGPL-2.1 )
	abi_x86_32? ( metapackage )"
KEYWORDS="-* amd64"
IUSE="abi_x86_32"

DEPEND=""
RDEPEND="
	!abi_x86_32? (
		~app-emulation/emul-linux-x86-baselibs-${PV}
		~app-emulation/emul-linux-x86-db-${PV}
		~app-emulation/emul-linux-x86-gtklibs-${PV}
		~app-emulation/emul-linux-x86-medialibs-${PV}
		~app-emulation/emul-linux-x86-soundlibs-${PV}
	)
	abi_x86_32? (
		>=media-plugins/gst-plugins-meta-0.10-r9:0.10[abi_x86_32(-)]
	)"

src_prepare() {
	use abi_x86_32 || emul-linux-x86_src_prepare
}

src_install() {
	use abi_x86_32 || emul-linux-x86_src_install
}
