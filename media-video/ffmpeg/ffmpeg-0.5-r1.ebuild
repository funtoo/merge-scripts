# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/ffmpeg/ffmpeg-0.5-r1.ebuild,v 1.17 2009/10/22 09:39:49 ssuominen Exp $

EAPI=2

inherit eutils flag-o-matic multilib toolchain-funcs

DESCRIPTION="Complete solution to record, convert and stream audio and video.
Includes libavcodec."
HOMEPAGE="http://ffmpeg.org/"
SRC_URI="http://ffmpeg.org/releases/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="3dnow 3dnowext alsa altivec amr custom-cflags debug dirac doc ieee1394
	  +encode faac faad gsm ipv6 mmx mmxext +vorbis test +theora threads +x264
	  +xvid network +zlib sdl X mp3 oss schroedinger hardcoded-tables bindist
	  v4l v4l2 speex ssse3 vhook jpeg2k"

VIDEO_CARDS="nvidia"

for x in ${VIDEO_CARDS}; do
	IUSE="${IUSE} video_cards_${x}"
done

RDEPEND="vhook? ( >=media-libs/imlib2-1.4.0 >=media-libs/freetype-2 )
	sdl? ( >=media-libs/libsdl-1.2.10 )
	alsa? ( media-libs/alsa-lib )
	encode? (
		faac? ( media-libs/faac )
		mp3? (
			|| (
				>=media-sound/lame-3.98.2-r1
				<media-sound/lame-3.98
			)
		)
		vorbis? ( media-libs/libvorbis media-libs/libogg )
		theora? ( media-libs/libtheora[encode] media-libs/libogg )
		x264? ( >=media-libs/x264-0.0.20081006 <media-libs/x264-0.0.20090923 )
		xvid? ( >=media-libs/xvid-1.1.0 ) )
	faad? ( >=media-libs/faad2-2.6.1 )
	zlib? ( sys-libs/zlib )
	ieee1394? ( media-libs/libdc1394
				sys-libs/libraw1394 )
	dirac? ( media-video/dirac )
	gsm? ( >=media-sound/gsm-1.0.12-r1 )
	jpeg2k? ( >=media-libs/openjpeg-1.3-r2 )
	schroedinger? ( media-libs/schroedinger )
	speex? ( >=media-libs/speex-1.2_beta3 )
	X? ( x11-libs/libX11 x11-libs/libXext )
	amr? ( media-libs/amrnb media-libs/amrwb )
	video_cards_nvidia? (
		vdpau? ( >=x11-drivers/nvidia-drivers-180.29 )
	)"

DEPEND="${RDEPEND}
	>=sys-devel/make-3.81
	mmx? ( dev-lang/yasm )
	doc? ( app-text/texi2html )
	test? ( net-misc/wget )
	v4l? ( sys-kernel/linux-headers )
	v4l2? ( sys-kernel/linux-headers )"

src_configure() {
	local myconf="${EXTRA_FFMPEG_CONF}"

	# enabled by default
	use debug || myconf="${myconf} --disable-debug"
	use zlib || myconf="${myconf} --disable-zlib"
	use sdl || myconf="${myconf} --disable-ffplay"

	if use network; then
		use ipv6 || myconf="${myconf} --disable-ipv6"
	else
		myconf="${myconf} --disable-network"
	fi

	use custom-cflags && myconf="${myconf} --disable-optimizations"

	# enabled by default
	if use encode
	then
		use faac && myconf="${myconf} --enable-libfaac"
		use mp3 && myconf="${myconf} --enable-libmp3lame"
		use vorbis && myconf="${myconf} --enable-libvorbis"
		use theora && myconf="${myconf} --enable-libtheora"
		use x264 && myconf="${myconf} --enable-libx264"
		use xvid && myconf="${myconf} --enable-libxvid"
	else
		myconf="${myconf} --disable-encoders"
	fi

	# libavdevice options
	use ieee1394 && myconf="${myconf} --enable-libdc1394"
	# Demuxers
	for i in v4l v4l2 alsa oss ; do
		use $i || myconf="${myconf} --disable-demuxer=$i"
	done
	# Muxers
	for i in alsa oss ; do
		use $i || myconf="${myconf} --disable-muxer=$i"
	done
	use X && myconf="${myconf} --enable-x11grab"

	# Threads; we only support pthread for now but ffmpeg supports more
	use threads && myconf="${myconf} --enable-pthreads"

	# Decoders
	use faad && myconf="${myconf} --enable-libfaad"
	use dirac && myconf="${myconf} --enable-libdirac"
	use schroedinger && myconf="${myconf} --enable-libschroedinger"
	use speex && myconf="${myconf} --enable-libspeex"
	use jpeg2k && myconf="${myconf} --enable-libopenjpeg"
	if use gsm; then
		myconf="${myconf} --enable-libgsm"
		# Crappy detection or our installation is weird, pick one (FIXME)
		append-flags -I/usr/include/gsm
	fi
	if use bindist
	then
		use amr && ewarn "libamr is nonfree and cannot be distributed; disabling amr support."
	else
		use amr && myconf="${myconf} --enable-libamr-nb \
									 --enable-libamr-wb \
									 --enable-nonfree"
	fi

	# This has changed since 0.5, please recheck for next version
	if use video_cards_nvidia; then
		use vdpau && myconf="${myconf} --enable-vdpau"
	fi

	# CPU features
	for i in mmx ssse3 altivec ; do
		use $i ||  myconf="${myconf} --disable-$i"
	done
	use mmxext || myconf="${myconf} --disable-mmx2"
	use 3dnow || myconf="${myconf} --disable-amd3dnow"
	use 3dnowext || myconf="${myconf} --disable-amd3dnowext"
	# disable mmx accelerated code if PIC is required
	# as the provided asm decidedly is not PIC.
	if gcc-specs-pie ; then
		myconf="${myconf} --disable-mmx --disable-mmx2"
	fi

	# Try to get cpu type based on CFLAGS.
	# Bug #172723
	# We need to do this so that features of that CPU will be better used
	# If they contain an unknown CPU it will not hurt since ffmpeg's configure
	# will just ignore it.
	for i in $(get-flag march) $(get-flag mcpu) $(get-flag mtune) ; do
		myconf="${myconf} --cpu=$i"
		break
	done

	# video hooking support. replaced by libavfilter, probably needs to be
	# dropped at some point.
	use vhook || myconf="${myconf} --disable-vhook"

	# Mandatory configuration
	myconf="${myconf} --enable-gpl --enable-postproc \
			--enable-avfilter --enable-avfilter-lavf \
			--enable-swscale --disable-stripping"

	# cross compile support
	tc-is-cross-compiler && myconf="${myconf} --enable-cross-compile --arch=$(tc-arch-kernel)"

	# Misc stuff
	use hardcoded-tables && myconf="${myconf} --enable-hardcoded-tables"

	# Specific workarounds for too-few-registers arch...
	if [[ $(tc-arch) == "x86" ]]; then
		filter-flags -fforce-addr -momit-leaf-frame-pointer
		append-flags -fomit-frame-pointer
		is-flag -O? || append-flags -O2
		if (use debug); then
			# no need to warn about debug if not using debug flag
			ewarn ""
			ewarn "Debug information will be almost useless as the frame pointer is omitted."
			ewarn "This makes debugging harder, so crashes that has no fixed behavior are"
			ewarn "difficult to fix. Please have that in mind."
			ewarn ""
		fi
	fi

	cd "${S}"
	./configure \
		--prefix=/usr \
		--libdir=/usr/$(get_libdir) \
		--shlibdir=/usr/$(get_libdir) \
		--mandir=/usr/share/man \
		--enable-static --enable-shared \
		--cc="$(tc-getCC)" \
		${myconf} || die "configure failed"
}

src_compile() {
	emake version.h || die #252269
	emake || die "make failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "Install Failed"

	dodoc Changelog README INSTALL
	dodoc doc/*
}

# Never die for now...
src_test() {
	for t in codectest libavtest seektest ; do
		emake ${t} || ewarn "Some tests in ${t} failed"
	done
}
