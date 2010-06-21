# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/mplayer/mplayer-1.0_rc2_p20090731-r1.ebuild,v 1.7 2009/10/26 23:54:15 ssuominen Exp $

EAPI=2
inherit eutils flag-o-matic multilib

MPLAYER_REVISION=SVN-r29463

IUSE="3dnow 3dnowext +a52 +aac aalib +alsa altivec +ass
bidi bindist bl +cddb +cdio cdparanoia cpudetection custom-cflags
custom-cpuopts debug dga +dirac directfb doc +dts +dv dvb +dvd +dvdnav dxr3
+enca +encode esd +faac +faad fbcon ftp gif ggi -gmplayer +iconv ipv6 jack
joystick jpeg kernel_linux ladspa libcaca lirc +live lzo mad md5sum +mmx
mmxext mng +mp2 +mp3 nas +network nut openal +opengl opencore-amr +osdmenu
oss png pnm pulseaudio pvr +quicktime radio +rar +real +rtc samba +shm
+schroedinger sdl +speex sse sse2 ssse3 svga teletext tga +theora +tremor
+truetype +unicode v4l v4l2 vdpau vidix +vorbis win32codecs X +x264 xanim
xinerama +xscreensaver +xv +xvid xvmc zoran"

VIDEO_CARDS="s3virge mga tdfx nvidia vesa"

for x in ${VIDEO_CARDS}; do
	IUSE="${IUSE} video_cards_${x}"
done

BLUV="1.7"
SVGV="1.9.17"
AMR_URI="http://www.3gpp.org/ftp/Specs/archive"
SRC_URI="mirror://gentoo/${P}.tar.bz2
	!truetype? ( mirror://mplayer/releases/fonts/font-arial-iso-8859-1.tar.bz2
				 mirror://mplayer/releases/fonts/font-arial-iso-8859-2.tar.bz2
				 mirror://mplayer/releases/fonts/font-arial-cp1250.tar.bz2 )
	!iconv? ( mirror://mplayer/releases/fonts/font-arial-iso-8859-1.tar.bz2
			  mirror://mplayer/releases/fonts/font-arial-iso-8859-2.tar.bz2
			  mirror://mplayer/releases/fonts/font-arial-cp1250.tar.bz2 )
	gmplayer? ( mirror://mplayer/skins/Blue-${BLUV}.tar.bz2 )
	svga? ( http://dev.gentoo.org/~ssuominen/svgalib_helper-${SVGV}-mplayer.tar.gz )"
#	svga? ( http://mplayerhq.hu/~alex/svgalib_helper-${SVGV}-mplayer.tar.bz2 )

DESCRIPTION="Media Player for Linux"
HOMEPAGE="http://www.mplayerhq.hu/"

RDEPEND="sys-libs/ncurses
	!bindist? (
		x86? (
			win32codecs? ( media-libs/win32codecs )
			)
	)
	aalib? ( media-libs/aalib )
	alsa? ( media-libs/alsa-lib )
	opencore-amr? ( media-libs/opencore-amr )
	ass? ( || ( media-fonts/ttf-bitstream-vera media-fonts/dejavu )
		media-libs/freetype:2 media-libs/fontconfig )
	openal? ( media-libs/openal )
	bidi? ( dev-libs/fribidi )
	cdio? ( dev-libs/libcdio )
	cdparanoia? ( media-sound/cdparanoia )
	dirac? ( media-video/dirac )
	directfb? ( dev-libs/DirectFB )
	dga? ( x11-libs/libXxf86dga  )
	dts? ( media-libs/libdca )
	dv? ( media-libs/libdv )
	dvb? ( media-tv/linuxtv-dvb-headers )
	encode? (
		mp2? ( media-sound/twolame )
		mp3? ( media-sound/lame )
		faac? ( media-libs/faac )
		x264? ( >=media-libs/x264-0.0.20090629 <media-libs/x264-0.0.20090923 )
		xvid? ( media-libs/xvid )
		)
	esd? ( media-sound/esound )
	enca? ( app-i18n/enca )
	faad? ( !aac? ( media-libs/faad2 ) )
	gif? ( media-libs/giflib )
	ggi? ( media-libs/libggi
		media-libs/libggiwmh )
	gmplayer? ( media-libs/libpng
		x11-libs/libXxf86vm
		x11-libs/libXext
		x11-libs/libXi
		x11-libs/gtk+:2 )
	jack? ( media-sound/jack-audio-connection-kit )
	jpeg? ( media-libs/jpeg )
	ladspa? ( media-libs/ladspa-sdk )
	libcaca? ( media-libs/libcaca )
	lirc? ( app-misc/lirc )
	lzo? ( >=dev-libs/lzo-2 )
	mad? ( media-libs/libmad )
	mng? ( media-libs/libmng )
	nas? ( media-libs/nas )
	nut? ( >=media-libs/libnut-661 )
	opengl? ( virtual/opengl )
	png? ( media-libs/libpng )
	pnm? ( media-libs/netpbm )
	pulseaudio? ( media-sound/pulseaudio )
	rar? ( || ( app-arch/unrar-gpl
		app-arch/unrar
		app-arch/rar ) )
	samba? ( net-fs/samba )
	schroedinger? ( media-libs/schroedinger )
	sdl? ( media-libs/libsdl )
	speex? ( media-libs/speex )
	svga? ( media-libs/svgalib )
	theora? ( media-libs/libtheora )
	live? ( media-plugins/live )
	truetype? ( media-libs/freetype:2
		media-libs/fontconfig )
	video_cards_nvidia? (
		vdpau? ( >=x11-drivers/nvidia-drivers-180.60 )
	)
	vidix? ( x11-libs/libXxf86vm
			 x11-libs/libXext )
	vorbis? ( media-libs/libvorbis )
	xanim? ( media-video/xanim )
	xinerama? ( x11-libs/libXinerama
		x11-libs/libXxf86vm
		x11-libs/libXext )
	xscreensaver? ( x11-libs/libXScrnSaver )
	xv? ( x11-libs/libXv
		x11-libs/libXxf86vm
		x11-libs/libXext
		xvmc? ( x11-libs/libXvMC ) )
	X? ( x11-libs/libXxf86vm
		x11-libs/libXext
	)"

DEPEND="${RDEPEND}
	amd64? ( dev-lang/yasm )
	doc? ( dev-libs/libxslt )
	dga? ( x11-proto/xf86dgaproto )
	dxr3? ( media-video/em8300-libraries )
	xinerama? ( x11-proto/xineramaproto )
	xv? ( x11-proto/videoproto
		  x11-proto/xf86vidmodeproto )
	gmplayer? ( x11-proto/xextproto
		   x11-proto/xf86vidmodeproto )
	X? ( x11-proto/xextproto
		 x11-proto/xf86vidmodeproto )
	x86? ( dev-lang/yasm )
	x86-fbsd? ( dev-lang/yasm )
	xscreensaver? ( x11-proto/scrnsaverproto )
	iconv? ( virtual/libiconv )"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc64 ~x86 ~x86-fbsd"

pkg_setup() {
	if use gmplayer; then
		ewarn ""
		ewarn "GMPlayer is no longer actively developed upstream"
		ewarn "and is not supported by Gentoo.  There are alternatives"
		ewarn "for a GUI frontend: smplayer, gnome-mplayer and kmplayer."
	fi

	if use cpudetection; then
		ewarn ""
		ewarn "You've enabled the cpudetection flag.  This feature is"
		ewarn "included mainly for people who want to use the same"
		ewarn "binary on another system with a different CPU architecture."
		ewarn "MPlayer will already detect your CPU settings by default at"
		ewarn "buildtime; this flag is used for runtime detection."
		ewarn "You won't need this turned on if you are only building"
		ewarn "mplayer for this system.  Also, if your compile fails, try"
		ewarn "disabling this use flag."
	fi

	if use custom-cflags; then
		ewarn ""
		ewarn "You've enabled the custom-cflags USE flag, which overrides"
		ewarn "mplayer's recommended behavior, making this build unsupported."
		ewarn ""
		ewarn "Re-emerge mplayer without this flag before filing bugs."
	fi

	if use custom-cpuopts; then
		ewarn ""
		ewarn "You are using the custom-cpuopts flag which will"
		ewarn "specifically allow you to enable / disable certain"
		ewarn "CPU optimizations."
		ewarn ""
		ewarn "Most desktop users won't need this functionality, but it"
		ewarn "is included for corner cases like cross-compiling and"
		ewarn "certain profiles.  If unsure, disable this flag and MPlayer"
		ewarn "will automatically detect and use your available CPU"
		ewarn "optimizations."
		ewarn ""
		ewarn "Using this flag means your build is unsupported, so"
		ewarn "please make sure your CPU optimization use flags (3dnow"
		ewarn "3dnowext mmx mmxext sse sse2 ssse3) are properly set."
	fi
}

src_unpack() {
	unpack ${A}

	if ! use truetype ; then
		unpack font-arial-iso-8859-1.tar.bz2 \
			font-arial-iso-8859-2.tar.bz2 \
			font-arial-cp1250.tar.bz2
	fi

	cd "${WORKDIR}"

	use gmplayer && unpack "Blue-${BLUV}.tar.bz2"

	use svga && unpack "svgalib_helper-${SVGV}-mplayer.tar.gz"
}

src_prepare() {
	# Set version #
	sed -i s/UNKNOWN/${MPLAYER_REVISION}/ "${S}/version.sh"

	if use svga; then
		echo
		einfo "Enabling vidix non-root mode."
		einfo "(You need a proper svgalib_helper.o module for your kernel"
		einfo "to actually use this)"
		echo

		mv "${WORKDIR}/svgalib_helper" "${S}/libdha"
	fi

	epatch "${FILESDIR}"/${PN}-1.0_rc2_p20090530-fix-mp3lib-use-local-labels-2.patch
	epatch "${FILESDIR}"/${P}-linguas.patch
}

src_configure() {
	local myconf=""

	[[ -n $LINGUAS ]] && LINGUAS="${LINGUAS/da/dk}"

	# mplayer ebuild uses "use foo || --disable-foo" to forcibly disable
	# compilation in almost every situation.  The reason for this is
	# because if --enable is used, it will force the build of that option,
	# regardless of whether the dependency is available or not.

	################
	#Optional features#
	###############
	myconf="${myconf} $(use_enable network) --disable-arts --disable-nemesi"
	use ass || myconf="${myconf} --disable-ass"
	use bidi || myconf="${myconf} --disable-fribidi"
	use bl && myconf="${myconf} --enable-bl"
	use enca || myconf="${myconf} --disable-enca"
	use encode || myconf="${myconf} --disable-mencoder"
	use ftp || myconf="${myconf} --disable-ftp"
	use ipv6 || myconf="${myconf} --disable-inet6"
	use lirc || myconf="${myconf} --disable-lirc --disable-lircc \
		--disable-apple-ir"
	use nut || myconf="${myconf} --disable-libnut"
	use osdmenu && myconf="${myconf} --enable-menu"
	use rar || myconf="${myconf} --disable-unrarexec"
	use rtc || myconf="${myconf} --disable-rtc"
	use samba || myconf="${myconf} --disable-smb"
	use xscreensaver || myconf="${myconf} --disable-xss"
	myconf="${myconf} $(use_enable joystick)"

	# libcdio support: prefer libcdio over cdparanoia
	# don't check for cddb w/cdio
	if use cdio; then
		myconf="${myconf} --disable-cdparanoia"
	else
		myconf="${myconf} --disable-libcdio"
		use cdparanoia || myconf="${myconf} --disable-cdparanoia"
		use cddb || myconf="${myconf} --disable-cddb"
	fi

	###############
	# DVD read, navigation support
	###############
	#
	# dvdread - accessing a DVD
	# dvdnav - navigation of menus
	#
	# internal dvdread and dvdnav use flags enable internal
	# versions of the libraries, which are snapshots of the fork.
	#
	# Only check for disabled a52 use flag inside the DVD check,
	# since many users were getting confused why there was no
	# audio stream.
	#
	if use dvd; then
		use dvdnav || myconf="${myconf} --disable-dvdnav"
	else
		myconf="${myconf} --disable-dvdnav --disable-dvdread
			--disable-dvdread-internal --disable-libdvdcss-internal"
		use a52 || myconf="${myconf} --disable-liba52-internal"
	fi

	###############
	# Subtitles
	###############
	#
	# SRT/ASS/SSA (subtitles) requires freetype support
	# freetype support requires iconv
	# iconv optionally can use unicode
	if ! use ass; then
		if ! use truetype; then
			myconf="${myconf} --disable-freetype"
			if ! use iconv; then
				myconf="${myconf} --disable-iconv --charset=noconv"
			fi
		fi
	fi
	use iconv && use unicode && myconf="${myconf} --charset=UTF-8"

	###############
	# DVB / Video4Linux / Radio support
	###############
	myconf="${myconf} --disable-tv-bsdbt848"
	# broken upstream, won't work with recent kernels
	myconf="${myconf} --disable-ivtv"
	if { use dvb || use v4l || use v4l2 || use pvr || use radio; }; then
		use dvb || myconf="${myconf} --disable-dvb --disable-dvbhead"
		use pvr || myconf="${myconf} --disable-pvr"
		use v4l	|| myconf="${myconf} --disable-tv-v4l1"
		use v4l2 || myconf="${myconf} --disable-tv-v4l2"
		use teletext || myconf="${myconf} --disable-tv-teletext"
		if use radio && { use dvb || use v4l || use v4l2; }; then
			myconf="${myconf} --enable-radio $(use_enable encode radio-capture)"
		else
			myconf="${myconf} --disable-radio-v4l2 --disable-radio-bsdbt848"
		fi
	else
		myconf="${myconf} --disable-tv --disable-tv-v4l1 --disable-tv-v4l2
			--disable-radio --disable-radio-v4l2 --disable-radio-bsdbt848
			--disable-dvb --disable-dvbhead --disable-tv-teletext
			--disable-v4l2 --disable-pvr"
	fi

	#########
	# Codecs #
	########
	# Won't work with external liba52
	myconf="${myconf} --disable-liba52"
	# Use internal musepack codecs for SV7 and SV8 support
	myconf="${myconf} --disable-musepack"

	use opencore-amr || myconf="${myconf} --disable-libopencore_amrnb
		--disable-libopencore_amrwb"
	use aac || myconf="${myconf} --disable-faad-internal"
	use dirac || myconf="${myconf} --disable-libdirac-lavc"
	use dts || myconf="${myconf} --disable-libdca"
	use dv || myconf="${myconf} --disable-libdv"
	use faad || myconf="${myconf} --disable-faad"
	use lzo || myconf="${myconf} --disable-liblzo"
	use mp3 || myconf="${myconf} --disable-mp3lame --disable-mp3lame-lavc
		--disable-mp3lib"
	use schroedinger || myconf="${myconf} --disable-libschroedinger-lavc"
	use xanim && myconf="${myconf} --xanimcodecsdir=/usr/lib/xanim/mods"
	! use png && ! use gmplayer && myconf="${myconf} --disable-png"
	for x in gif jpeg live mad mng pnm speex tga theora xanim; do
		use ${x} || myconf="${myconf} --disable-${x}"
	done
	if use vorbis || use tremor; then
		use tremor || myconf="${myconf} --disable-tremor-internal"
		use vorbis || myconf="${myconf} --disable-libvorbis"
	else
		myconf="${myconf} --disable-tremor-internal --disable-tremor
			--disable-libvorbis"
	fi
	# Encoding
	if use encode; then
		use aac || myconf="${myconf} --disable-faac-lavc"
		use faac || myconf="${myconf} --disable-faac"
		use x264 || myconf="${myconf} --disable-x264"
		use xvid || myconf="${myconf} --disable-xvid"
		use mp2 || myconf="${myconf} --disable-twolame --disable-toolame"
	else
		myconf="${myconf} --disable-faac-lavc --disable-faac --disable-x264 \
			--disable-xvid --disable-x264-lavc --disable-xvid-lavc \
			--disable-twolame --disable-toolame"
	fi

	###############
	# Binary codecs
	###############
	# bug 213836
	if ! use x86 || ! use win32codecs; then
		use quicktime || myconf="${myconf} --disable-qtx"
	fi

	###############
	# RealPlayer support
	###############
	#
	# Realplayer support shows up in four places:
	# - libavcodec (internal)
	# - win32codecs
	# - realcodecs (win32codecs libs)
	# - realcodecs (realplayer libs)
	#

	# internal
	use real || myconf="${myconf} --disable-real"

	# Real binary codec support only available on x86, amd64
	if use real; then
		use x86 && myconf="${myconf}
			--realcodecsdir=/opt/RealPlayer/codecs"
		use amd64 && myconf="${myconf}
			 --realcodecsdir=/usr/$(get_libdir)/codecs"
	elif ! use bindist; then
			myconf="${myconf} $(use_enable win32codecs win32dll)"
	fi

	#############
	# Video Output #
	#############
	for x in directfb ggi md5sum sdl xinerama; do
		use ${x} || myconf="${myconf} --disable-${x}"
	done
	use aalib || myconf="${myconf} --disable-aa"
	use dga || myconf="${myconf} --disable-dga1 --disable-dga2"
	use dxr3 || myconf="${myconf} --disable-dxr3"
	use fbcon || myconf="${myconf} --disable-fbdev"
	use fbcon && use video_cards_s3virge && myconf="${myconf} --enable-s3fb"
	use libcaca || myconf="${myconf} --disable-caca"
	use opengl || myconf="${myconf} --disable-gl"
	use video_cards_vesa || myconf="${myconf} --disable-vesa"
	use video_cards_nvidia && use vdpau || myconf="${myconf} --disable-vdpau"
	use vidix || myconf="${myconf} --disable-vidix --disable-vidix-pcidb"
	use zoran || myconf="${myconf} --disable-zr"

	# GTK gmplayer gui
	# Unsupported by Gentoo, upstream has dropped development
	myconf="${myconf} $(use_enable gmplayer gui)"

	if use xv; then
		if use xvmc; then
			myconf="${myconf} --enable-xvmc --with-xvmclib=XvMCW"
		else
			myconf="${myconf} --disable-xvmc"
		fi
	else
		myconf="${myconf} --disable-xv --disable-xvmc"
	fi

	if ! use kernel_linux && ! use video_cards_mga; then
		 myconf="${myconf} --disable-mga --disable-xmga"
	fi

	if use video_cards_tdfx; then
		myconf="${myconf} $(use_enable video_cards_tdfx tdfxvid)
			$(use_enable fbcon tdfxfb)"
	else
		myconf="${myconf} --disable-3dfx --disable-tdfxvid --disable-tdfxfb"
	fi

	#############
	# Audio Output #
	#############
	for x in alsa esd jack ladspa nas openal; do
		use ${x} || myconf="${myconf} --disable-${x}"
	done
	use pulseaudio || myconf="${myconf} --disable-pulse"
	if ! use radio; then
		use oss || myconf="${myconf} --disable-ossaudio"
	fi

	#################
	# Advanced Options #
	#################
	# Platform specific flags, hardcoded on amd64 (see below)
	if use cpudetection; then
		myconf="${myconf} --enable-runtime-cpudetection"
	fi

	# Turning off CPU optimizations usually will break the build.
	# However, this use flag, if enabled, will allow users to completely
	# specify which ones to use.  If disabled, mplayer will automatically
	# enable all CPU optimizations that the host build supports.
	if use custom-cpuopts; then
		for x in 3dnow 3dnowext altivec mmx mmxext shm sse sse2 ssse3; do
			myconf="${myconf} $(use_enable $x)"
		done
	fi

	use debug && myconf="${myconf} --enable-debug=3"

	if use custom-cflags; then

		# ugly optimizations cause MPlayer to cry on x86 systems!
			if use x86 || use x86-fbsd ; then
				replace-flags -O* -O2
				filter-flags -fPIC -fPIE

				use debug || append-flags -fomit-frame-pointer
			fi
		append-flags -D__STDC_LIMIT_MACROS
	else
		unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS YASMFLAGS
	fi

	myconf="--cc=$(tc-getCC)
		--host-cc=$(tc-getBUILD_CC)
		--prefix=/usr
		--confdir=/etc/mplayer
		--datadir=/usr/share/mplayer
		--libdir=/usr/$(get_libdir)
		${myconf}"

	#echo "CFLAGS=\"${CFLAGS}\" ./configure ${myconf}"
	CFLAGS="${CFLAGS}" ./configure ${myconf} || die "configure died"

}

src_compile() {
	emake || die "Failed to build MPlayer!"
	use doc && make -C DOCS/xml html-chunked
}

src_install() {

	make prefix="${D}/usr" \
		BINDIR="${D}/usr/bin" \
		LIBDIR="${D}/usr/$(get_libdir)" \
		CONFDIR="${D}/etc/mplayer" \
		DATADIR="${D}/usr/share/mplayer" \
		MANDIR="${D}/usr/share/man" \
		INSTALLSTRIP="" \
		install || die "Failed to install MPlayer!"

	dodoc AUTHORS Changelog Copyright README etc/codecs.conf

	docinto tech/
	dodoc DOCS/tech/{*.txt,MAINTAINERS,mpsub.sub,playtree,TODO,wishlist}
	docinto TOOLS/
	dodoc TOOLS/*
	if use real; then
		docinto tech/realcodecs/
		dodoc DOCS/tech/realcodecs/*
		docinto TOOLS/realcodecs/
		dodoc TOOLS/realcodecs/*
	fi
	docinto tech/mirrors/
	dodoc DOCS/tech/mirrors/*

	use doc && dohtml -r "${S}"/DOCS/HTML/*

	# Install the default Skin and Gnome menu entry
	if use gmplayer; then
		dodir /usr/share/mplayer/skins
		cp -r "${WORKDIR}/Blue" \
			"${D}/usr/share/mplayer/skins/default" || die "cp skins died"

		# Fix the symlink
		rm -rf "${D}/usr/bin/gmplayer"
		dosym mplayer /usr/bin/gmplayer
	fi

	if ! use ass && ! use truetype; then
		dodir /usr/share/mplayer/fonts
		local x=
		# Do this generic, as the mplayer people like to change the structure
		# of their zips ...
		for x in $(find "${WORKDIR}/" -type d -name 'font-arial-*')
		do
			cp -pPR "${x}" "${D}/usr/share/mplayer/fonts"
		done
		# Fix the font symlink ...
		rm -rf "${D}/usr/share/mplayer/font"
		dosym fonts/font-arial-14-iso-8859-1 /usr/share/mplayer/font
	fi

	insinto /etc/mplayer
	newins "${S}/etc/example.conf" mplayer.conf
	doins "${S}/etc/input.conf"
	use osdmenu && doins "${S}/etc/menu.conf"

	if use ass || use truetype;	then
		cat >> "${D}/etc/mplayer/mplayer.conf" << EOT
fontconfig=1
subfont-osd-scale=4
subfont-text-scale=3
EOT
	fi

	# bug 256203
	if use rar; then
		cat >> "${D}/etc/mplayer/mplayer.conf" << EOT
unrarexec=/usr/bin/unrar
EOT
	fi

	dosym ../../../etc/mplayer/mplayer.conf /usr/share/mplayer/mplayer.conf

	newbin "${S}/TOOLS/midentify.sh" midentify

}

pkg_preinst() {

	if [[ -d ${ROOT}/usr/share/mplayer/Skin/default ]]
	then
		rm -rf "${ROOT}/usr/share/mplayer/Skin/default"
	fi
}

pkg_postrm() {

	# Cleanup stale symlinks
	if [ -L "${ROOT}/usr/share/mplayer/font" -a \
		 ! -e "${ROOT}/usr/share/mplayer/font" ]
	then
		rm -f "${ROOT}/usr/share/mplayer/font"
	fi

	if [ -L "${ROOT}/usr/share/mplayer/subfont.ttf" -a \
		 ! -e "${ROOT}/usr/share/mplayer/subfont.ttf" ]
	then
		rm -f "${ROOT}/usr/share/mplayer/subfont.ttf"
	fi
}
