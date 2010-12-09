# Copyright 2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="3"

inherit fdo-mime

DESCRIPTION="foobar2000-like music player."
HOMEPAGE="http://deadbeef.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"
LICENSE="GPL-2 ZLIB
	dumb? ( DUMB-0.9.2 )
	shorten? ( shorten )
	audiooverload? ( BSD XMAME )"

## TODO:
##	add shorten license to portage
##	enable gtk3 support when available in portage

SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="aac adplug alsa audiooverload cdda cover curl dts dumb ffmpeg flac gme +gtk hotkeys lastfm libnotify mac midi mms mp3 musepack nls null oss pulseaudio rpath shellexec shorten sid sndfile supereq threads tta vorbis vtx wavpack"

RDEPEND="
	media-libs/libsamplerate
	gtk? ( x11-libs/gtk+:2 )
	alsa? ( media-libs/alsa-lib )
	vorbis? ( media-libs/libvorbis )
	cover? ( net-misc/curl )
	curl? ( net-misc/curl )
	lastfm? ( net-misc/curl )
	mp3? ( media-libs/libmad )
	flac? ( media-libs/flac )
	wavpack? ( media-sound/wavpack )
	sndfile? ( media-libs/libsndfile )
	cdda? ( dev-libs/libcdio media-libs/libcddb )
	ffmpeg? ( media-video/ffmpeg )
	hotkeys? ( x11-libs/libX11 )
	libnotify? ( sys-apps/dbus )
	pulseaudio? ( media-sound/pulseaudio )
	aac? ( media-libs/faad2 )
	audiooverload? ( sys-libs/zlib )
	midi? ( media-sound/timidity-freepats )
	"
DEPEND="${RDEPEND}"

src_prepare() {
	if use midi; then
		# set default gentoo path
		sed -e 's;/etc/timidity++/timidity-freepats.cfg;/usr/share/timidity/freepats/timidity.cfg;g' \
			-i "${S}/plugins/wildmidi/wildmidiplug.c"
	fi
}

src_configure() {
	my_config="--disable-dependency-tracking
		$(use_enable nls)
		$(use_enable threads)
		$(use_enable rpath)
		$(use_enable null nullout)
		$(use_enable alsa)
		$(use_enable oss)
		$(use_enable pulseaudio pulse)
		$(use_enable gtk gtkui)
		--disable-gtk3
		$(use_enable supereq)
		$(use_enable sid)
		$(use_enable mp3 mad)
		$(use_enable mac ffap)
		$(use_enable vtx)
		$(use_enable adplug)
		$(use_enable hotkeys)
		$(use_enable vorbis)
		$(use_enable ffmpeg)
		$(use_enable flac)
		$(use_enable sndfile)
		$(use_enable wavpack)
		$(use_enable cdda)
		$(use_enable gme)
		$(use_enable dumb)
		$(use_enable libnotify notify)
		$(use_enable shellexec)
		$(use_enable musepack)
		$(use_enable midi wildmidi)
		$(use_enable tta)
		$(use_enable dts dca)
		$(use_enable aac)
		$(use_enable mms)
		$(use_enable shorten shn)
		$(use_enable audiooverload ao)"
	
	# artowrk and lastfm plugins both require curl
	if use cover || use lastfm ; then
		my_config="${my_config}
			--enable-vfs-curl
			$(use_enable cover artwork)
			$(use_enable lastfm lfm)"
	else
		my_config="${my_config}
			--disable-artwork
			--disable-lfm
			$(use_enable curl vfs-curl)"
	fi

	econf ${my_config} || die
}

src_install() {
	einstall
}
