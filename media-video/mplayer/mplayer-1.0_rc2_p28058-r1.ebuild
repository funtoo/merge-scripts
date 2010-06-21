# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/mplayer/mplayer-1.0_rc2_p28058-r1.ebuild,v 1.9 2009/03/24 21:32:35 yngwin Exp $

EAPI="1"

inherit eutils flag-o-matic multilib

# Ugly hack, feel free to fix
MPLAYER_REVISION=28058

IUSE="3dnow 3dnowext +a52 +aac -aalib +alsa altivec amrnb amrwb -arts +ass bidi bl
bindist cddb cdio cdparanoia -cpudetection -custom-cflags -custom-cpuopts debug
dga dirac doc dts dvb directfb +dvd dvdnav dv dxr3 enca +encode esd -fbcon ftp -gif ggi
-gtk iconv ipv6 jack joystick -jpeg kernel_linux ladspa -libcaca lirc live lzo
+mad -md5sum +mmx mmxext mng mp2 +mp3 musepack nas nemesi opengl
openal oss -png -pnm pulseaudio -pvr +quicktime radio -rar real rtc -samba schroedinger sdl
speex sse sse2 ssse3 svga teletext tga +theora +truetype unicode v4l v4l2
vidix +vorbis win32codecs -X +x264 xanim xinerama -xscreensaver +xv +xvid xvmc zoran"

VIDEO_CARDS="s3virge mga tdfx vesa"

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
	gtk? ( mirror://mplayer/Skin/Blue-${BLUV}.tar.bz2 )
	svga? ( http://mplayerhq.hu/~alex/svgalib_helper-${SVGV}-mplayer.tar.bz2 )"

DESCRIPTION="Media Player for Linux"
HOMEPAGE="http://www.mplayerhq.hu/"

RDEPEND="sys-libs/ncurses
	!bindist? (
		x86? (
			win32codecs? ( media-libs/win32codecs )
			real? ( media-libs/win32codecs
				media-libs/realcodecs )
			)
		amd64? ( real? ( media-libs/amd64codecs ) )
	)
	aalib? ( media-libs/aalib )
	alsa? ( media-libs/alsa-lib )
	amrnb? ( media-libs/amrnb )
	amrwb? ( media-libs/amrwb )
	arts? ( kde-base/arts )
	ass? ( >=media-libs/freetype-2.1
		media-libs/fontconfig )
	openal? ( media-libs/openal )
	bidi? ( dev-libs/fribidi )
	cdio? ( dev-libs/libcdio )
	cdparanoia? ( media-sound/cdparanoia )
	dirac? ( >=media-video/dirac-0.10.0 )
	directfb? ( dev-libs/DirectFB )
	dga? ( x11-libs/libXxf86dga  )
	dts? ( media-libs/libdca )
	dvdnav? ( >=media-libs/libdvdnav-4.1.3
		>=media-libs/libdvdread-4.1.3 )
	dv? ( media-libs/libdv )
	dvb? ( media-tv/linuxtv-dvb-headers )
	encode? (
		aac? ( media-libs/faac )
		mp2? ( media-sound/twolame )
		mp3? ( media-sound/lame )
		x264? ( >=media-libs/x264-0.0.20080406 )
		)
	esd? ( media-sound/esound )
	enca? ( app-i18n/enca )
	gif? ( media-libs/giflib )
	ggi? ( media-libs/libggi
		media-libs/libggiwmh )
	gtk? ( media-libs/libpng
		x11-libs/libXxf86vm
		x11-libs/libXext
		x11-libs/libXi
		=x11-libs/gtk+-2* )
	jpeg? ( media-libs/jpeg )
	ladspa? ( media-libs/ladspa-sdk )
	libcaca? ( media-libs/libcaca )
	lirc? ( app-misc/lirc )
	lzo? ( >=dev-libs/lzo-2 )
	mad? ( media-libs/libmad )
	mng? ( media-libs/libmng )
	musepack? ( >=media-libs/libmpcdec-1.2.2 )
	nas? ( media-libs/nas )
	opengl? ( virtual/opengl )
	png? ( media-libs/libpng )
	pnm? ( media-libs/netpbm )
	pulseaudio? ( media-sound/pulseaudio )
	samba? ( net-fs/samba )
	schroedinger? ( media-libs/schroedinger )
	sdl? ( media-libs/libsdl )
	speex? ( >=media-libs/speex-1.1.7 )
	svga? ( media-libs/svgalib )
	theora? ( media-libs/libtheora )
	live? ( >=media-plugins/live-2007.02.20 )
	truetype? ( >=media-libs/freetype-2.1
		media-libs/fontconfig )
	vidix? ( x11-libs/libXxf86vm
			 x11-libs/libXext )
	xanim? ( media-video/xanim )
	xinerama? ( x11-libs/libXinerama
		x11-libs/libXxf86vm
		x11-libs/libXext )
	xscreensaver? ( x11-libs/libXScrnSaver )
	xv? ( x11-libs/libXv
		x11-libs/libXxf86vm
		x11-libs/libXext
		xvmc? ( x11-libs/libXvMC ) )
	xvid? ( media-libs/xvid )
	X? ( x11-libs/libXxf86vm
		x11-libs/libXext
	)"

DEPEND="${RDEPEND}
	doc? ( dev-libs/libxslt )
	dga? ( x11-proto/xf86dgaproto )
	dxr3? ( media-video/em8300-libraries )
	xinerama? ( x11-proto/xineramaproto )
	xv? ( x11-proto/videoproto
		  x11-proto/xf86vidmodeproto )
	gtk? ( x11-proto/xextproto
		   x11-proto/xf86vidmodeproto )
	X? ( x11-proto/xextproto
		 x11-proto/xf86vidmodeproto )
	xscreensaver? ( x11-proto/scrnsaverproto )
	iconv? ( virtual/libiconv )"
# Make sure the assembler USE flags are unmasked on amd64
# Remove this once default-linux/amd64/2006.1 is deprecated
DEPEND="${DEPEND} amd64? ( >=sys-apps/portage-2.1.2 )
	mp2? ( >=sys-apps/portage-2.1.2 )"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="alpha amd64 hppa ia64 ~mips ppc ppc64 sparc x86 ~x86-fbsd"

pkg_setup() {

	if [[ -n ${LINGUAS} ]]; then
		elog ""
		elog "MPlayer's build system uses the LINGUAS variable for both"
		elog "output messages and which man pages to build.  The first"
		elog "language in the LINGUAS variable will be used to display"
		elog "output messages.  See bug #228799."
	fi

	if use gtk; then
		ewarn ""
		ewarn "You've enabled the 'gtk' use flag which will build"
		ewarn "GMPlayer, which is no longer actively developed upstream"
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

	use gtk && unpack "Blue-${BLUV}.tar.bz2"

	use svga && unpack "svgalib_helper-${SVGV}-mplayer.tar.bz2"

	cd "${S}"

	# Fix sparc compilation, bug 241110
	epatch "${FILESDIR}/mplayer-libavcodec.patch"

	# Fix x264 compilation, bug 240347
	epatch "${FILESDIR}/mplayer-1.0_rc2_p27725-libx264.patch"

	# Security bug 251017
	epatch "${FILESDIR}"/mplayer-1.0_rc2_p28058-demux_vqf.patch

	# Set version #
	sed -i s/UNKNOWN/${MPLAYER_REVISION}/ "${S}/version.sh"

	# Fix hppa compilation
	use hppa && sed -i -e "s/-O4/-O1/" "${S}/configure"

	if use svga; then
		echo
		einfo "Enabling vidix non-root mode."
		einfo "(You need a proper svgalib_helper.o module for your kernel"
		einfo "to actually use this)"
		echo

		mv "${WORKDIR}/svgalib_helper" "${S}/libdha"
	fi

	# Fix polish spelling errors
	[[ -n ${LINGUAS} ]] && sed -e 's:Zarządano:Zażądano:' -i help/help_mp-pl.h
}

src_compile() {

	local myconf=" --disable-tv-bsdbt848 \
		--disable-faad"

	# broken upstream, won't work with recent kernels
	myconf="${myconf} --disable-ivtv"

	# MPlayer reads in the LINGUAS variable from make.conf, and sets
	# the languages accordingly.  Some will have to be altered to match
	# upstream's naming scheme.
	[[ -n $LINGUAS ]] && LINGUAS=${LINGUAS/da/dk}

	################
	#Optional features#
	###############
	use ass || myconf="${myconf} --disable-ass"
	use bidi || myconf="${myconf} --disable-fribidi"
	use bl && myconf="${myconf} --enable-bl"
	use enca || myconf="${myconf} --disable-enca"
	use encode || myconf="${myconf} --disable-mencoder"
	use ftp || myconf="${myconf} --disable-ftp"
	use nemesi || myconf="${myconf} --disable-nemesi"
	use xscreensaver || myconf="${myconf} --disable-xss"

	# libcdio support: prefer libcdio over cdparanoia
	# don't check for cddb w/cdio
	if use cdio; then
		myconf="${myconf} --disable-cdparanoia"
	else
		myconf="${myconf} --disable-libcdio"
		use cdparanoia || myconf="${myconf} --disable-cdparanoia"
		use cddb || myconf="${myconf} --disable-cddb"
	fi

	# DVD support
	# dvdread and libdvdcss are internal libs
	# http://www.mplayerhq.hu/DOCS/HTML/en/dvd.html
	# You can optionally use external dvdread/dvdnav support.
	if use dvdnav; then
		myconf="${myconf} --with-dvdread-config=/usr/bin/dvdread-config \
			--with-dvdnav-config=/usr/bin/dvdnav-config \
			--disable-dvdread-internal"
	elif ! use dvd && ! use dvdread; then
		myconf="${myconf} --disable-dvdnav --disable-dvdread"
		use a52 || myconf="${myconf} --disable-liba52 \
			--disable-liba52-internal"
	fi

	# SRT (subtitles) requires freetype support
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

	use lirc || myconf="${myconf} --disable-lirc --disable-lircc"
	myconf="${myconf} $(use_enable joystick)"
	use ipv6 || myconf="${myconf} --disable-inet6"
	use rar || myconf="${myconf} --disable-unrarexec"
	use rtc || myconf="${myconf} --disable-rtc"
	use samba || myconf="${myconf} --disable-smb"

	# DVB / Video4Linux / Radio support
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
		myconf="${myconf} --disable-tv --disable-tv-v4l1 --disable-tv-v4l2 \
			--disable-radio --disable-radio-v4l2 --disable-radio-bsdbt848 \
			--disable-dvb --disable-dvbhead --disable-tv-teletext \
			--disable-v4l2 --disable-pvr"
	fi

	#########
	# Codecs #
	########
	for x in gif jpeg live mad musepack pnm speex tga theora xanim; do
		use ${x} || myconf="${myconf} --disable-${x}"
	done
	for x in dirac schroedinger ; do
		use ${x} || myconf="${myconf} --disable-lib${x}-lavc"
	done
	use aac || myconf="${myconf} --disable-faac --disable-faac-lavc"
	use amrnb || myconf="${myconf} --disable-libamr_nb"
	use amrwb || myconf="${myconf} --disable-libamr_wb"
	use dts || myconf="${myconf} --disable-libdca"
	use dv || myconf="${myconf} --disable-libdv"
	! use png && ! use gtk && myconf="${myconf} --disable-png"
	use lzo || myconf="${myconf} --disable-liblzo"
	use encode && use mp2 || myconf="${myconf} --disable-twolame \
		--disable-toolame"
	use mp3 || myconf="${myconf} --disable-mp3lame --disable-mp3lame-lavc"
	use vorbis || myconf="${myconf} --disable-libvorbis"
	use x264 || myconf="${myconf} --disable-x264 --disable-x264-lavc"
	use xanim && myconf="${myconf} --xanimcodecsdir=/usr/lib/xanim/mods"
	use xvid || myconf="${myconf} --disable-xvid --disable-xvid-lavc"

	# Real codec support, only available on x86, amd64
	if use real && use x86; then
		myconf="${myconf} --realcodecsdir=/opt/RealPlayer/codecs"
	elif use real && use amd64; then
		myconf="${myconf} --realcodecsdir=/usr/$(get_libdir)/codecs"
	else
		myconf="${myconf} --disable-real"
	fi
	if ! use bindist && ! use real; then
		myconf="${myconf} $(use_enable win32codecs win32dll)"
	fi
	# bug 213836
	if ! use x86 || ! use win32codecs; then
		use quicktime || myconf="${myconf} --disable-qtx"
	fi

	#############
	# Video Output #
	#############
	for x in directfb ggi md5sum sdl xinerama; do
		use ${x} || myconf="${myconf} --disable-${x}"
	done
	use aalib || myconf="${myconf} --disable-aa"
	use dga || myconf="${myconf} --disable-dga1 --disable-dga2"
	use fbcon || myconf="${myconf} --disable-fbdev"
	use fbcon && use video_cards_s3virge && myconf="${myconf} --enable-s3fb"
	use libcaca || myconf="${myconf} --disable-caca"
	use opengl || myconf="${myconf} --disable-gl"
	use video_cards_vesa || myconf="${myconf} --disable-vesa"
	use vidix || myconf="${myconf} --disable-vidix \
		--disable-vidix-pcidb"
	use zoran || myconf="${myconf} --disable-zr"

	# MPlayer incorrectly looks for DXR3 support, so forcibly enable
	# if requested. See bug 223587
	myconf="${myconf} $(use_enable dxr3)"

	# GTK gmplayer gui
	myconf="${myconf} $(use_enable gtk gui)"

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
		myconf="${myconf} $(use_enable video_cards_tdfx tdfxvid) \
			$(use_enable fbcon tdfxfb)"
	else
		myconf="${myconf} --disable-3dfx --disable-tdfxvid --disable-tdfxfb"
	fi

	#############
	# Audio Output #
	#############
	for x in alsa arts esd jack ladspa nas openal; do
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
	if use cpudetection || use bindist; then
		myconf="${myconf} --enable-runtime-cpudetection"
	fi

	# Turning off CPU optimizations usually will break the build.
	# However, this use flag, if enabled, will allow users to completely
	# specify which ones to use.  If disabled, mplayer will automatically
	# enable all CPU optimizations that the host build supports.
	if use custom-cpuopts; then
		for x in 3dnow 3dnowext mmx mmxext sse sse2 ssse3; do
			myconf="${myconf} $(use_enable $x)"
		done
	fi

	use debug && myconf="${myconf} --enable-debug=3"

	myconf="${myconf} $(use_enable altivec)"

	if use custom-cflags; then
		# let's play the filtration game!  MPlayer hates on all!
		strip-flags
		# ugly optimizations cause MPlayer to cry on x86 systems!
			if use x86 || use x86-fbsd ; then
				replace-flags -O* -O2
				filter-flags -fPIC -fPIE

				use debug || append-flags -fomit-frame-pointer
			fi
		append-flags -D__STDC_LIMIT_MACROS
	else
		unset CFLAGS CXXFLAGS
	fi

	myconf="--cc=$(tc-getCC) \
		--host-cc=$(tc-getBUILD_CC) \
		--prefix=/usr \
		--confdir=/etc/mplayer \
		--datadir=/usr/share/mplayer \
		--libdir=/usr/$(get_libdir) \
		--enable-menu \
		--enable-network \
		${myconf}"

	#echo "CFLAGS=\"${CFLAGS}\" ./configure ${myconf}"
	CFLAGS="${CFLAGS}" ./configure ${myconf} || die "configure died"

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

	dodoc AUTHORS Changelog README etc/codecs.conf
	# Install the documentation; DOCS is all mixed up not just html
	if use doc ; then
		find "${S}/DOCS" -type d | xargs -- chmod 0755
		find "${S}/DOCS" -type f | xargs -- chmod 0644
		cp -r "${S}/DOCS" "${D}/usr/share/doc/${PF}/" || die "cp docs died"
	fi

	# Copy misc tools to documentation path, as they're not installed directly
	# and yes, we are nuking the +x bit.
	find "${S}/TOOLS" -type d | xargs -- chmod 0755
	find "${S}/TOOLS" -type f | xargs -- chmod 0644
	cp -r "${S}/TOOLS" "${D}/usr/share/doc/${PF}/" || die "cp docs died"

	# Install the default Skin and Gnome menu entry
	if use gtk; then
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

	if use ass || use truetype;	then
		cat >> "${D}/etc/mplayer/mplayer.conf" << EOT
fontconfig=1
subfont-osd-scale=4
subfont-text-scale=3
EOT
	fi

	dosym ../../../etc/mplayer/mplayer.conf /usr/share/mplayer/mplayer.conf

	newbin "${S}/TOOLS/midentify.sh" midentify

	insinto /usr/share/mplayer
	doins "${S}/etc/input.conf"
	doins "${S}/etc/menu.conf"
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
