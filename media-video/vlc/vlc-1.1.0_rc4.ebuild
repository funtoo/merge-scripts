# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/vlc/vlc-1.1.0_rc4.ebuild,v 1.1 2010/06/16 08:18:45 aballier Exp $

EAPI="2"

SCM=""
if [ "${PV%9999}" != "${PV}" ] ; then
	SCM=git
	EGIT_BOOTSTRAP="bootstrap"
	EGIT_BRANCH=master
	EGIT_PROJECT=${P}
	if [ "${PV%.9999}" != "${PV}" ] ; then
		EGIT_REPO_URI="git://git.videolan.org/vlc/vlc-${PV%.9999}.git"
	else
		EGIT_REPO_URI="git://git.videolan.org/vlc.git"
	fi
fi

inherit eutils multilib autotools toolchain-funcs gnome2 nsplugins qt4 flag-o-matic ${SCM}

MY_PV="${PV/_/-}"
MY_PV="${MY_PV/-beta/-test}"
MY_P="${PN}-${MY_PV}"
VLC_SNAPSHOT_TIME="0013"

PATCHLEVEL="85"
DESCRIPTION="VLC media player - Video player and streamer"
HOMEPAGE="http://www.videolan.org/vlc/"
if [ "${PV%9999}" != "${PV}" ] ; then # Live ebuild
	SRC_URI=""
elif [[ "${P}" == *_alpha* ]]; then # Snapshots taken from nightlies.videolan.org
	SRC_URI="http://nightlies.videolan.org/build/source/trunk-${PV/*_alpha/}-${VLC_SNAPSHOT_TIME}/${PN}-snapshot-${PV/*_alpha/}.tar.bz2"
	MY_P="${P/_alpha*/}-git"
elif [[ "${MY_P}" == "${P}" ]]; then
	SRC_URI="http://download.videolan.org/pub/videolan/${PN}/${PV}/${P}.tar.bz2"
else
	SRC_URI="http://download.videolan.org/pub/videolan/testing/${MY_P}/${MY_P}.tar.bz2"
fi

SRC_URI="${SRC_URI}
	mirror://gentoo/${PN}-patches-${PATCHLEVEL}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"

KEYWORDS="~alpha ~amd64 ~arm ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="a52 aac aalib alsa altivec atmo avahi bidi cdda cddb dbus dc1394
	debug dirac directfb dts dvb dvd elibc_glibc fbcon fluidsynth +ffmpeg flac fontconfig
	+gcrypt ggi gnome gnutls httpd id3tag ieee1394 jack kate kde libass libcaca
	libnotify libproxy libtiger libv4l libv4l2 lirc live lua matroska mmx
	modplug mp3 mpeg mtp musepack ncurses nsplugin ogg opengl optimisememory oss
	png projectm pulseaudio pvr +qt4 remoteosd rtsp run-as-root samba
	schroedinger sdl sdl-image shine shout skins speex sqlite sse stream
	svg svga taglib theora truetype twolame udev upnp v4l v4l2 vaapi vcdx vlm
	vorbis win32codecs wma-fixed +X x264 +xcb xml xosd xv zvbi"

RDEPEND="
		!!<=media-video/vlc-1.0.99999
		sys-libs/zlib
		>=media-libs/libdvbpsi-0.1.6
		a52? ( >=media-libs/a52dec-0.7.4-r3 )
		aalib? ( media-libs/aalib )
		aac? ( >=media-libs/faad2-2.6.1 )
		alsa? ( media-libs/alsa-lib )
		avahi? ( >=net-dns/avahi-0.6[dbus] )
		bidi? ( >=dev-libs/fribidi-0.10.4 )
		cdda? (	cddb? ( >=media-libs/libcddb-1.2.0 ) )
		dbus? ( >=sys-apps/dbus-1.0.2 )
		dc1394? ( >=sys-libs/libraw1394-2.0.1
			>=media-libs/libdc1394-2.0.2 )
		dirac? ( >=media-video/dirac-0.10.0 )
		directfb? ( dev-libs/DirectFB sys-libs/zlib )
		dts? ( media-libs/libdca )
		dvd? (	media-libs/libdvdread >=media-libs/libdvdnav-0.1.9 )
		elibc_glibc? ( >=sys-libs/glibc-2.8 )
		ffmpeg? ( >=media-video/ffmpeg-0.4.9_p20090201 )
		flac? ( media-libs/libogg
			>=media-libs/flac-1.1.2 )
		fluidsynth? ( media-sound/fluidsynth )
		fontconfig? ( media-libs/fontconfig )
		gcrypt? ( >=dev-libs/libgcrypt-1.2.0 )
		ggi? ( media-libs/libggi )
		gnome? ( gnome-base/gnome-vfs )
		gnutls? ( >=net-libs/gnutls-1.7.4 )
		id3tag? ( media-libs/libid3tag sys-libs/zlib )
		ieee1394? ( >=sys-libs/libraw1394-2.0.1 >=sys-libs/libavc1394-0.5.3 )
		jack? ( >=media-sound/jack-audio-connection-kit-0.99.0-r1 )
		kate? ( >=media-libs/libkate-0.1.1 )
		libass? ( >=media-libs/libass-0.9.6 media-libs/fontconfig )
		libcaca? ( >=media-libs/libcaca-0.99_beta14 )
		libnotify? ( x11-libs/libnotify )
		libproxy? ( net-libs/libproxy )
		libtiger? ( media-libs/libtiger )
		lirc? ( app-misc/lirc )
		live? ( >=media-plugins/live-2008.07.06 )
		lua? ( >=dev-lang/lua-5.1 )
		matroska? (
			>=dev-libs/libebml-0.7.6
			>=media-libs/libmatroska-0.8.0 )
		modplug? ( >=media-libs/libmodplug-0.8 )
		mp3? ( media-libs/libmad )
		mpeg? ( >=media-libs/libmpeg2-0.3.2 )
		mtp? ( >=media-libs/libmtp-1.0.0 )
		musepack? ( >=media-sound/musepack-tools-444 )
		ncurses? ( sys-libs/ncurses )
		nsplugin? ( >=net-libs/xulrunner-1.9.2 x11-libs/libXpm x11-libs/libXt )
		ogg? ( media-libs/libogg )
		opengl? ( virtual/opengl )
		png? ( media-libs/libpng sys-libs/zlib )
		projectm? ( media-libs/libprojectm )
		pulseaudio? ( >=media-sound/pulseaudio-0.9.11
			!X? ( >=media-sound/pulseaudio-0.9.11[-X] ) )
		qt4? ( x11-libs/qt-gui:4 x11-libs/qt-core:4 x11-libs/libX11 )
		remoteosd? ( >=dev-libs/libgcrypt-1.2.0 )
		samba? ( || ( >=net-fs/samba-3.4.6[smbclient]
			<net-fs/samba-3.4 ) )
		schroedinger? ( >=media-libs/schroedinger-1.0.6 )
		sdl? ( >=media-libs/libsdl-1.2.8
			sdl-image? ( media-libs/sdl-image sys-libs/zlib	) )
		shout? ( media-libs/libshout )
		skins? (
				x11-libs/qt-gui:4 x11-libs/qt-core:4
				x11-libs/libXext x11-libs/libX11
				media-libs/freetype media-fonts/dejavu
			   )
		speex? ( media-libs/speex )
		sqlite? ( >=dev-db/sqlite-3.6.0:3 )
		svg? ( >=gnome-base/librsvg-2.9.0 )
		svga? ( media-libs/svgalib )
		taglib? ( >=media-libs/taglib-1.5 sys-libs/zlib )
		theora? ( >=media-libs/libtheora-1.0_beta3 )
		truetype? ( media-libs/freetype
			media-fonts/dejavu )
		twolame? ( media-sound/twolame )
		udev? ( >=sys-fs/udev-142 )
		upnp? ( net-libs/libupnp )
		v4l2? ( libv4l2? ( media-libs/libv4l ) )
		v4l? ( libv4l? ( media-libs/libv4l ) )
		vaapi? ( x11-libs/libva >=media-video/ffmpeg-0.5_p22846 )
		vcdx? ( >=dev-libs/libcdio-0.78.2 >=media-video/vcdimager-0.7.22 )
		vorbis? ( media-libs/libvorbis )
		win32codecs? ( media-libs/win32codecs )
		X? ( x11-libs/libX11 )
		x264? ( >=media-libs/x264-0.0.20090923 )
		xcb? ( x11-libs/libxcb x11-libs/xcb-util )
		xml? ( dev-libs/libxml2 )
		xosd? ( x11-libs/xosd )
		zvbi? ( >=media-libs/zvbi-0.2.25 )
		"

DEPEND="${RDEPEND}
	dvb? ( sys-kernel/linux-headers )
	kde? ( >=kde-base/kdelibs-4 )
	v4l? ( sys-kernel/linux-headers )
	v4l2? ( >=sys-kernel/linux-headers-2.6.25 )
	xcb? ( x11-proto/xproto )
	dev-util/pkgconfig"

S="${WORKDIR}/${MY_P}"

# Displays a warning if the first use flag is set but the second is not
vlc_use_needs() {
	use $1 && use !$2 && ewarn "USE=$1 requires $2, $1 will be disabled."
}

# Notify the user that some useflag have been forced on
vlc_use_force() {
	use $1 && use !$2 && ewarn "USE=$1 requires $2, $2 will be enabled."
}

# Use when $1 depends strictly on $2
# if use $1 then enable $2
vlc_use_enable_force() {
	use $1 && echo "--enable-$2"
}

pkg_setup() {
	if has_version '<=media-video/vlc-1.0.99999'; then
		eerror "Please unmerge vlc-1.0.x first before installing ${P}"
		eerror "If you don't do that, some plugins will get linked against"
		eerror "the old ${PN} version and will not work."
		die "Unmerge vlc 1.0.x first"
	fi

	# Useflags we need to forcefuly enable
	vlc_use_force remoteosd gcrypt
	vlc_use_force skins truetype
	vlc_use_force skins qt4
	vlc_use_force vlm stream
	vlc_use_force vaapi ffmpeg

	# Useflags that will be automagically discarded if deps are not met
	vlc_use_needs bidi truetype
	vlc_use_needs cddb cdda
	vlc_use_needs fontconfig truetype
	vlc_use_needs libv4l2 v4l2
	vlc_use_needs libv4l v4l
	vlc_use_needs libtiger kate
	vlc_use_needs xv xcb

	if use qt4 || use skins ; then
		qt4_pkg_setup
	else
		ewarn "You have disabled the qt4 useflag, ${PN} will not have any"
		ewarn "graphical interface. Maybe that is not what you want..."
	fi
}

src_unpack() {
	unpack ${A}
	if [ "${PV%9999}" != "${PV}" ] ; then
		git_src_unpack
	fi
}

src_prepare() {
	if [ "${PV%9999}" != "${PV}" ] ; then
		git_src_prepare
	fi
	# Make it build with libtool 1.5
	rm -f m4/lt* m4/libtool.m4

	EPATCH_SUFFIX="patch" epatch "${WORKDIR}/patches"
	eautoreconf
}

src_configure() {

	# It would fail if -fforce-addr is used due to too few registers...
	use x86 && filter-flags -fforce-addr

	econf \
		$(use_enable a52) \
		$(use_enable aalib aa) \
		$(use_enable aac faad) \
		$(use_enable alsa) \
		$(use_enable altivec) \
		--disable-asademux \
		$(use_enable atmo) \
		$(use_enable avahi bonjour) \
		$(use_enable bidi fribidi) \
		$(use_enable cdda vcd) \
		$(use_enable cddb libcddb) \
		$(use_enable dbus) $(use_enable dbus dbus-control) \
		$(use_enable dirac) \
		$(use_enable directfb) \
		$(use_enable dc1394) \
		$(use_enable debug) \
		$(use_enable dts dca) \
		$(use_enable dvb) \
		$(use_enable dvd dvdread) $(use_enable dvd dvdnav) \
		$(use_enable fbcon fb) \
		$(use_enable ffmpeg avcodec) $(use_enable ffmpeg avformat) $(use_enable ffmpeg swscale) $(use_enable ffmpeg postproc) \
		$(use_enable flac) \
		$(use_enable fluidsynth) \
		$(use_enable fontconfig) \
		$(use_enable ggi) \
		$(use_enable gnome gnomevfs) \
		$(use_enable gnutls) \
		$(use_enable httpd) \
		$(use_enable id3tag) \
		$(use_enable ieee1394 dv) \
		$(use_enable jack) \
		$(use_enable kate) \
		$(use_with kde kde-solid) \
		$(use_enable libass) \
		$(use_enable libcaca caca) \
		$(use_enable gcrypt libgcrypt) \
		$(use_enable libnotify notify) \
		$(use_enable libproxy) \
		--disable-libtar \
		$(use_enable libtiger tiger) \
		$(use_enable libv4l) \
		$(use_enable libv4l2) \
		$(use_enable lirc) \
		$(use_enable live live555) \
		$(use_enable lua) \
		$(use_enable matroska mkv) \
		$(use_enable mmx) \
		$(use_enable modplug mod) \
		$(use_enable mp3 mad) \
		$(use_enable mpeg libmpeg2) \
		$(use_enable mtp) \
		$(use_enable musepack mpc) \
		$(use_enable ncurses) \
		$(use_enable nsplugin mozilla) --with-mozilla-pkg=libxul \
		$(use_enable ogg) \
		$(use_enable opengl glx) $(use_enable opengl) \
		$(use_enable optimisememory optimize-memory) \
		$(use_enable oss) \
		$(use_enable png) \
		--disable-portaudio \
		$(use_enable projectm) \
		$(use_enable pulseaudio pulse) \
		$(use_enable pvr) \
		$(use_enable qt4) \
		$(use_enable remoteosd) \
		$(use_enable rtsp realrtsp) \
		$(use_enable run-as-root) \
		$(use_enable samba smb) \
		$(use_enable schroedinger) \
		$(use_enable sdl) \
		$(use_enable sdl-image) \
		$(use_enable shine) \
		$(use_enable shout) \
		$(use_enable skins skins2) \
		$(use_enable speex) \
		$(use_enable sqlite) \
		$(use_enable sse) \
		$(use_enable stream sout) \
		$(use_enable svg) \
		$(use_enable svga svgalib) \
		$(use_enable taglib) \
		$(use_enable theora) \
		$(use_enable truetype freetype) \
		$(use_enable twolame) \
		$(use_enable udev) \
		$(use_enable upnp) \
		$(use_enable v4l) \
		$(use_enable v4l2) \
		$(use_enable vcdx) \
		$(use_enable vaapi libva) \
		$(use_enable vlm) \
		$(use_enable vorbis) \
		$(use_enable win32codecs loader) \
		$(use_enable wma-fixed) \
		$(use_with X x) \
		$(use_enable x264) \
		$(use_enable xcb) \
		$(use_enable xml libxml2) \
		$(use_enable xosd) \
		$(use_enable xv xvideo) \
		$(use_enable zvbi) $(use_enable !zvbi telx) \
		--disable-snapshot \
		--disable-growl \
		--disable-optimizations \
		--enable-fast-install \
		$(vlc_use_enable_force vlm sout) \
		$(vlc_use_enable_force skins qt4) \
		$(vlc_use_enable_force skins freetype) \
		$(vlc_use_enable_force remoteosd libgcrypt) \
		$(vlc_use_enable_force vaapi avcodec)
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"

	dodoc AUTHORS HACKING THANKS NEWS README \
		doc/fortunes.txt doc/intf-vcd.txt

	rm -rf "${D}/usr/share/doc/vlc" \
		"${D}"/usr/share/vlc/vlc{16x16,32x32,48x48,128x128}.{png,xpm,ico}

	if use nsplugin; then
		dodir "/usr/$(get_libdir)/${PLUGINS_DIR}"
		mv "${D}"/usr/$(get_libdir)/mozilla/plugins/* \
			"${D}/usr/$(get_libdir)/${PLUGINS_DIR}/"
	fi

	use skins || rm -rf "${D}/usr/share/vlc/skins2"

	for res in 16 32 48; do
		insinto /usr/share/icons/hicolor/${res}x${res}/apps/
		newins "${S}"/share/vlc${res}x${res}.png vlc.png
	done
}

pkg_postinst() {
	gnome2_pkg_postinst

	if [ "$ROOT" = "/" ] && [ -x "/usr/$(get_libdir)/vlc/vlc-cache-gen" ] ; then
		einfo "Running /usr/$(get_libdir)/vlc/vlc-cache-gen on /usr/$(get_libdir)/vlc/plugins/"
		"/usr/$(get_libdir)/vlc/vlc-cache-gen" -f "/usr/$(get_libdir)/vlc/plugins/"
	else
		ewarn "We cannot run vlc-cache-gen (most likely ROOT!=/)"
		ewarn "Please run /usr/$(get_libdir)/vlc/vlc-cache-gen manually"
		ewarn "If you do not do it, vlc will take a long time to load."
	fi
}
