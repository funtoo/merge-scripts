# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-tv/xbmc/xbmc-9.11-r3.ebuild,v 1.6 2010/05/23 18:38:59 vapier Exp $

EAPI="2"

inherit eutils

# Use XBMC_ESVN_REPO_URI to track a different branch
ESVN_REPO_URI=${XBMC_ESVN_REPO_URI:-http://xbmc.svn.sourceforge.net/svnroot/xbmc/trunk}
ESVN_PROJECT=${ESVN_REPO_URI##*/svnroot/}
ESVN_PROJECT=${ESVN_PROJECT%/*}
if [[ ${PV} == "9999" ]] ; then
	inherit subversion autotools
	KEYWORDS=""
else
	inherit autotools
	MY_P=${P/_/-}
	SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S=${WORKDIR}/${MY_P}
fi

DESCRIPTION="XBMC is a free and open source media-player and entertainment hub"
HOMEPAGE="http://xbmc.org/"

LICENSE="GPL-2"
SLOT="0"
IUSE="aac alsa altivec avahi css debug joystick midi profile pulseaudio sse sse2 vdpau xrandr"

RDEPEND="virtual/opengl
	app-arch/bzip2
	app-arch/unrar
	app-arch/unzip
	app-arch/zip
	app-i18n/enca
	>=dev-lang/python-2.4
	dev-libs/boost
	dev-libs/fribidi
	dev-libs/libcdio
	dev-libs/libpcre
	dev-libs/lzo
	>=dev-python/pysqlite-2
	media-libs/a52dec
	media-libs/alsa-lib
	aac? ( media-libs/faac )
	media-libs/faad2
	media-libs/flac
	media-libs/fontconfig
	media-libs/freetype
	media-libs/glew
	media-libs/jasper
	media-libs/jbigkit
	media-libs/jpeg:0
	>=media-libs/libass-0.9.7
	media-libs/libdca
	css? ( media-libs/libdvdcss )
	media-libs/libmad
	media-libs/libmms
	media-libs/libmpeg2
	media-libs/libogg
	media-libs/libsamplerate
	media-libs/libsdl[alsa,audio,video,X]
	media-libs/libvorbis
	media-libs/sdl-gfx
	media-libs/sdl-image[gif,jpeg,png]
	media-libs/sdl-mixer
	media-libs/sdl-sound
	media-libs/tiff
	pulseaudio? ( media-sound/pulseaudio )
	media-sound/wavpack
	media-video/ffmpeg
	avahi? ( net-dns/avahi )
	net-misc/curl
	|| ( >=net-fs/samba-3.4.6[smbclient] <net-fs/samba-3.3 )
	sys-apps/dbus
	sys-apps/hal
	sys-libs/zlib
	virtual/mysql
	x11-apps/xdpyinfo
	x11-apps/mesa-progs
	vdpau? (
		|| ( x11-libs/libvdpau >=x11-drivers/nvidia-drivers-180.51 )
		media-video/ffmpeg[vdpau]
	)
	x11-libs/libXinerama
	xrandr? ( x11-libs/libXrandr )
	x11-libs/libXrender"
DEPEND="${RDEPEND}
	x11-proto/xineramaproto
	dev-util/cmake
	x86? ( dev-lang/nasm )"

src_unpack() {
	if [[ ${PV} == "9999" ]] ; then
		subversion_src_unpack
		cd "${S}"
		rm -f configure
	else
		unpack ${A}
		cd "${S}"
	fi

	# Fix case sensitivity
	mv media/Fonts/{a,A}rial.ttf || die
	mv media/{S,s}plash.png || die
}

src_prepare() {
	has_version ">=media-libs/libpng-1.4" && epatch \
		"${FILESDIR}"/${P}-libpng14.patch

	epatch "${FILESDIR}"/${P}-wavpack.patch
	epatch "${FILESDIR}"/${P}-jpeg-speedup.patch #300909
	epatch "${FILESDIR}"/${P}-use-cdio-system-headers-on-non-win32.patch #303030, upstream: #8026
	# http://xbmc.org/trac/ticket/8218
	sed -i \
		-e 's: ftell64: dll_ftell64:' \
		xbmc/cores/DllLoader/exports/wrapper.c || die
	sed -i \
		-e '1i#include <stdlib.h>\n#include <string.h>\n' \
		xbmc/lib/libid3tag/libid3tag/metadata.c || die

	# some dirs ship generated autotools, some dont
	local d
	for d in . xbmc/cores/dvdplayer/Codecs/libbdnav ; do
		[[ -d ${d} ]] || continue
		[[ -e ${d}/configure ]] && continue
		pushd ${d} >/dev/null
		einfo "Generating autotools in ${d}"
		eautoreconf
		popd >/dev/null
	done

	local squish #290564
	use altivec && squish="-DSQUISH_USE_ALTIVEC=1 -maltivec"
	use sse && squish="-DSQUISH_USE_SSE=1 -msse"
	use sse2 && squish="-DSQUISH_USE_SSE=2 -msse2"
	sed -i \
		-e '/^CXXFLAGS/{s:-D[^=]*=.::;s:-m[[:alnum:]]*::}' \
		-e "1iCXXFLAGS += ${squish}" \
		xbmc/lib/libsquish/Makefile.in || die

	# Fix XBMC's final version string showing as "exported"
	# instead of the SVN revision number.
	export SVN_REV=${ESVN_WC_REVISION:-exported}

	# Avoid lsb-release dependency
	sed -i \
		-e 's:/usr/bin/lsb_release -d:cat /etc/gentoo-release:' \
		xbmc/utils/SystemInfo.cpp

	# Do not use termcap #262822
	sed -i 's:-ltermcap::' xbmc/lib/libPython/Python/configure

	epatch_user #293109

	# Tweak autotool timestamps to avoid regeneration
	find . -type f -print0 | xargs -0 touch -r configure

}

src_configure() {
	# Disable documentation generation
	export ac_cv_path_LATEX=no
	# Avoid help2man
	export HELP2MAN=$(type -P help2man || echo true)

	econf \
		--disable-ccache \
		--disable-optimizations \
		--enable-external-libraries \
		--enable-goom \
		--enable-gl \
		$(use_enable avahi) \
		$(use_enable css dvdcss) \
		$(use_enable debug) \
		$(use_enable aac faac) \
		$(use_enable joystick) \
		$(use_enable midi mid) \
		$(use_enable profile profiling) \
		$(use_enable pulseaudio pulse) \
		$(use_enable vdpau) \
		$(use_enable xrandr)
}

src_install() {
	einstall || die "Install failed!"

	insinto /usr/share/xbmc/web/styles/
	doins -r "${S}"/web/*/styles/*/ || die

	insinto /usr/share/applications
	doins tools/Linux/xbmc.desktop
	doicon tools/Linux/xbmc.png

	dodoc README.linux
	rm "${D}"/usr/share/xbmc/{README.linux,LICENSE.GPL,*.txt}
}

pkg_postinst() {
	elog "Visit http://xbmc.org/wiki/?title=XBMC_Online_Manual"
}
