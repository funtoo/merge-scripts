# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit emul-linux-x86

LICENSE="APL-1.0 GPL-2 BSD BSD-2 public-domain LGPL-2 MPL-1.1 LGPL-2.1 !abi_x86_32? ( MPEG-4 )"
KEYWORDS="-* amd64"
IUSE="abi_x86_32"

DEPEND=""
RDEPEND="~app-emulation/emul-linux-x86-baselibs-${PV}
	~app-emulation/emul-linux-x86-xlibs-${PV}
	~app-emulation/emul-linux-x86-db-${PV}
	!<=app-emulation/emul-linux-x86-sdl-20081109
	!<=app-emulation/emul-linux-x86-soundlibs-20110101
	abi_x86_32? (
		>=media-libs/libvpx-1.2.0_pre20130625[abi_x86_32(-)]
		>=media-libs/xvid-1.3.2-r1[abi_x86_32(-)]
		>=media-sound/lame-3.99.5-r1[abi_x86_32(-)]
		>=media-libs/faac-1.28-r4[abi_x86_32(-)]
		>=media-libs/faad2-2.7-r3[abi_x86_32(-)]
		>=media-libs/libtheora-1.1.1-r1[abi_x86_32(-)]
		>=media-libs/libcuefile-477-r1[abi_x86_32(-)]
		>=media-libs/libreplaygain-477-r1[abi_x86_32(-)]
		>=media-libs/libmad-0.15.1b-r8[abi_x86_32(-)]
		>=media-libs/libdca-0.0.5-r3[abi_x86_32(-)]
		>=media-libs/speex-1.2_rc1-r2[abi_x86_32(-)]
		>=media-libs/libdvdread-4.2.0-r1[abi_x86_32(-)]
		>=media-libs/libdvdnav-4.2.0-r1[abi_x86_32(-)]
		>=media-libs/libv4l-0.9.5-r1[abi_x86_32(-)]
		>=media-libs/libid3tag-0.15.1b-r4[abi_x86_32(-)]
		>=media-libs/libshout-2.3.1-r1[abi_x86_32(-)]
		>=media-libs/libsidplay-2.1.1-r4:2[abi_x86_32(-)]
		>=media-libs/libsidplay-1.36.59-r1:1[abi_x86_32(-)]
		>=media-libs/x264-0.0.20130731[abi_x86_32(-)]
		>=media-libs/libiec61883-1.2.0-r1[abi_x86_32(-)]
		>=media-libs/a52dec-0.7.4-r7[abi_x86_32(-)]
		>=media-libs/libmimic-1.0.4-r2[abi_x86_32(-)]
		>=media-libs/libmms-0.6.2-r1[abi_x86_32(-)]
		>=media-libs/libvisual-0.4.0-r3:0.4[abi_x86_32(-)]
		>=media-libs/libmpeg2-0.5.1-r2[abi_x86_32(-)]
		>=dev-libs/liboil-0.3.17-r2[abi_x86_32(-)]
		>=sys-libs/libieee1284-0.2.11-r3[abi_x86_32(-)]
		>=dev-libs/fribidi-0.19.5-r2[abi_x86_32(-)]
		>=dev-libs/libcdio-0.90-r1[abi_x86_32(-)]
		>=dev-libs/libcdio-paranoia-0.90_p1-r1[abi_x86_32(-)]
		>=media-video/ffmpeg-0.10.12:0.10[abi_x86_32(-)]
		>=media-libs/libdv-1.0.0-r3[abi_x86_32(-)]
	)
	"
PDEPEND="~app-emulation/emul-linux-x86-soundlibs-${PV}"

src_prepare() {
	# Include all libv4l libs, bug #348277
	ALLOWED="${S}/usr/lib32/libv4l/"
	emul-linux-x86_src_prepare

	# Remove migrated stuff.
	use abi_x86_32 && rm -f $(cat "${FILESDIR}/remove-native")
}
