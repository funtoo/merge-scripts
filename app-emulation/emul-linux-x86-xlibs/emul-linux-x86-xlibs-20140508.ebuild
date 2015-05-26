# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit emul-linux-x86

SRC_URI="!abi_x86_32? ( ${SRC_URI} )"
LICENSE="!abi_x86_32? ( FTL GPL-2 MIT ) abi_x86_32? ( metapackage )"
KEYWORDS="-* amd64"
IUSE="abi_x86_32 opengl"

DEPEND=""
RDEPEND="
	!abi_x86_32? (
		~app-emulation/emul-linux-x86-baselibs-${PV}
		x11-libs/libX11
		opengl? ( app-emulation/emul-linux-x86-opengl )

		!media-libs/fontconfig[abi_x86_32(-)]
		!media-libs/freetype[abi_x86_32(-)]
		!x11-libs/libICE[abi_x86_32(-)]
		!x11-libs/libpciaccess[abi_x86_32(-)]
		!x11-libs/libSM[abi_x86_32(-)]
		!x11-libs/libvdpau[abi_x86_32(-)]
		!x11-libs/libX11[abi_x86_32(-)]
		!x11-libs/libXau[abi_x86_32(-)]
		!x11-libs/libXaw[abi_x86_32(-)]
		!x11-libs/libxcb[abi_x86_32(-)]
		!x11-libs/libXcomposite[abi_x86_32(-)]
		!x11-libs/libXcursor[abi_x86_32(-)]
		!x11-libs/libXdamage[abi_x86_32(-)]
		!x11-libs/libXdmcp[abi_x86_32(-)]
		!x11-libs/libXext[abi_x86_32(-)]
		!x11-libs/libXfixes[abi_x86_32(-)]
		!x11-libs/libXft[abi_x86_32(-)]
		!x11-libs/libXi[abi_x86_32(-)]
		!x11-libs/libXinerama[abi_x86_32(-)]
		!x11-libs/libXmu[abi_x86_32(-)]
		!x11-libs/libXp[abi_x86_32(-)]
		!x11-libs/libXpm[abi_x86_32(-)]
		!x11-libs/libXrandr[abi_x86_32(-)]
		!x11-libs/libXrender[abi_x86_32(-)]
		!x11-libs/libXScrnSaver[abi_x86_32(-)]
		!x11-libs/libXt[abi_x86_32(-)]
		!x11-libs/libXtst[abi_x86_32(-)]
		!x11-libs/libXv[abi_x86_32(-)]
		!x11-libs/libXvMC[abi_x86_32(-)]
		!x11-libs/libXxf86dga[abi_x86_32(-)]
		!x11-libs/libXxf86vm[abi_x86_32(-)] )
	abi_x86_32? (
		>=media-libs/fontconfig-2.10.92[abi_x86_32(-)]
		>=media-libs/freetype-2.5.0.1[abi_x86_32(-)]
		>=x11-libs/libICE-1.0.8-r1[abi_x86_32(-)]
		>=x11-libs/libpciaccess-0.13.1-r1[abi_x86_32(-)]
		>=x11-libs/libSM-1.2.1-r1[abi_x86_32(-)]
		>=x11-libs/libvdpau-0.7[abi_x86_32(-)]
		>=x11-libs/libX11-1.6.2[abi_x86_32(-)]
		>=x11-libs/libXau-1.0.7-r1[abi_x86_32(-)]
		>=x11-libs/libXaw-1.0.11-r2[abi_x86_32(-)]
		>=x11-libs/libxcb-1.9.1[abi_x86_32(-)]
		>=x11-libs/libXcomposite-0.4.4-r1[abi_x86_32(-)]
		>=x11-libs/libXcursor-1.1.14[abi_x86_32(-)]
		>=x11-libs/libXdamage-1.1.4-r1[abi_x86_32(-)]
		>=x11-libs/libXdmcp-1.1.1-r1[abi_x86_32(-)]
		>=x11-libs/libXext-1.3.2[abi_x86_32(-)]
		>=x11-libs/libXfixes-5.0.1[abi_x86_32(-)]
		>=x11-libs/libXft-2.3.1-r1[abi_x86_32(-)]
		>=x11-libs/libXi-1.7.2[abi_x86_32(-)]
		>=x11-libs/libXinerama-1.1.3[abi_x86_32(-)]
		>=x11-libs/libXmu-1.1.1-r1[abi_x86_32(-)]
		>=x11-libs/libXp-1.0.2[abi_x86_32(-)]
		>=x11-libs/libXpm-3.5.10-r1[abi_x86_32(-)]
		>=x11-libs/libXrandr-1.4.2[abi_x86_32(-)]
		>=x11-libs/libXrender-0.9.8[abi_x86_32(-)]
		>=x11-libs/libXScrnSaver-1.2.2-r1[abi_x86_32(-)]
		>=x11-libs/libXt-1.1.4[abi_x86_32(-)]
		>=x11-libs/libXtst-1.2.1-r1[abi_x86_32(-)]
		>=x11-libs/libXv-1.0.10[abi_x86_32(-)]
		>=x11-libs/libXvMC-1.0.8[abi_x86_32(-)]
		>=x11-libs/libXxf86dga-1.1.4[abi_x86_32(-)]
		>=x11-libs/libXxf86vm-1.1.3[abi_x86_32(-)] )"

src_prepare() {
	use abi_x86_32 || emul-linux-x86_src_prepare
}

src_install() {
	use abi_x86_32 || emul-linux-x86_src_install
}
