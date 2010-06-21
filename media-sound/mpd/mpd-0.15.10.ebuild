# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/mpd/mpd-0.15.10.ebuild,v 1.1 2010/05/31 19:23:17 angelos Exp $

EAPI=2
inherit eutils flag-o-matic multilib

DESCRIPTION="The Music Player Daemon (mpd)"
HOMEPAGE="http://www.musicpd.org"
SRC_URI="mirror://sourceforge/musicpd/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~hppa ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd"
IUSE="aac +alsa ao audiofile avahi bzip2 cdio cue +curl debug +fifo +ffmpeg flac
fluidsynth profile +id3 ipv6 jack lame lastfmradio libmms libsamplerate +mad
mikmod modplug musepack +network ogg oss pipe pulseaudio sid sqlite unicode
vorbis wavpack zip"

RDEPEND="!sys-cluster/mpich2
	>=dev-libs/glib-2.6:2
	aac? ( >=media-libs/faad2-2 )
	alsa? ( media-sound/alsa-utils )
	ao? ( >=media-libs/libao-0.8.4[alsa?,pulseaudio?] )
	audiofile? ( media-libs/audiofile )
	bzip2? ( app-arch/bzip2 )
	cdio? ( dev-libs/libcdio )
	cue? ( >=media-libs/libcue-0.13 )
	curl? ( net-misc/curl )
	ffmpeg? ( media-video/ffmpeg )
	flac? ( media-libs/flac[ogg?] )
	fluidsynth? ( media-sound/fluidsynth )
	network? ( >=media-libs/libshout-2
		!lame? ( !vorbis? ( media-libs/libvorbis ) ) )
	id3? ( media-libs/libid3tag )
	jack? ( media-sound/jack-audio-connection-kit )
	lame? ( network? ( media-sound/lame ) )
	libmms? ( >=media-libs/libmms-0.4 )
	libsamplerate? ( media-libs/libsamplerate )
	mad? ( media-libs/libmad )
	mikmod? ( media-libs/libmikmod )
	modplug? ( media-libs/libmodplug )
	musepack? ( >=media-sound/musepack-tools-444 )
	ogg? ( media-libs/libogg )
	pulseaudio? ( media-sound/pulseaudio )
	sid? ( >=media-libs/libsidplay-2.1.1-r2:2 )
	sqlite? ( dev-db/sqlite:3 )
	vorbis? ( media-libs/libvorbis )
	wavpack? ( media-sound/wavpack )
	avahi? ( net-dns/avahi )
	zip? ( dev-libs/zziplib )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

pkg_setup() {
	use network || ewarn "Icecast and Shoutcast streaming needs networking."
	use fluidsynth && ewarn "Using fluidsynth is discouraged by upstream."

	enewuser mpd "" "" "/var/lib/mpd" audio
}

src_prepare() {
	cp -f doc/mpdconf.example doc/mpdconf.dist || die "cp failed"
	epatch "${FILESDIR}"/0.15.1-mpdconf.patch
}

src_configure() {
	local mpdconf="--disable-dependency-tracking --enable-tcp --enable-un
		--disable-wildmidi --disable-libOggFLACtest --disable-documentation
		--docdir=${EPREFIX}/usr/share/doc/${PF}"

	if use network; then
		mpdconf+=" --enable-shout $(use_enable vorbis vorbis-encoder)
			--enable-httpd-output $(use_enable lame lame-encoder)"
		if ! use lame && ! use vorbis; then
			ewarn "At least one encoder is required, enabling vorbis for you."
			mpdconf+=" --enable-vorbis-encoder"
		fi
	else
		mpdconf+=" --disable-shout --disable-vorbis-encoder
			--disable-httpd-output --disable-lame-encoder"
	fi

	if use flac && use ogg; then
		mpdconf+=" --enable-oggflac"
	else
		mpdconf+=" --disable-oggflac"
	fi

	append-lfs-flags
	append-ldflags "-L/usr/$(get_libdir)/sidplay/builders"

	cd "${S}"

	econf \
		$(use_enable ipv6) $(use_enable cue) \
		$(use_enable sqlite) $(use_enable curl) \
		$(use_enable lastfmradio lastfm) $(use_enable libmms mms) \
		$(use_enable bzip2) $(use_enable zip) \
		$(use_enable cdio iso9660) $(use_enable id3) \
		$(use_enable audiofile) $(use_enable ffmpeg) \
		$(use_enable flac) $(use_enable mad) \
		$(use_enable mikmod) $(use_enable modplug) \
		$(use_enable musepack mpc) $(use_enable vorbis) \
		$(use_enable sid sidplay) $(use_enable fluidsynth) \
		$(use_enable wavpack) $(use_enable libsamplerate lsr) \
		$(use_enable alsa) $(use_enable ao) \
		$(use_enable fifo) $(use_enable pipe pipe-output) \
		$(use_enable jack) $(use_enable oss) \
		$(use_enable pulseaudio pulse) $(use_enable aac) \
		$(use_enable debug) $(use_enable profile gprof) \
		$(use_with avahi zeroconf avahi) \
		${mpdconf}
}

src_install() {
	dodir /var/run/mpd
	fowners mpd:audio /var/run/mpd
	fperms 750 /var/run/mpd
	keepdir /var/run/mpd

	emake DESTDIR="${D}" install || die "emake install failed"

	insinto /etc
	newins doc/mpdconf.example mpd.conf

	newinitd "${FILESDIR}"/mpd.rc mpd

	if use unicode; then
		dosed 's:^#filesystem_charset.*$:filesystem_charset "UTF-8":' \
			/etc/mpd.conf || die "dosed failed"
	fi

	diropts -m0755 -o mpd -g audio
	dodir /var/lib/mpd
	keepdir /var/lib/mpd
	dodir /var/lib/mpd/music
	keepdir /var/lib/mpd/music
	dodir /var/lib/mpd/playlists
	keepdir /var/lib/mpd/playlists
	dodir /var/log/mpd
	keepdir /var/log/mpd

	if use alsa; then
		dosed 's:need :need alsasound :' /etc/init.d/mpd || die "dosed failed"
	fi
}

pkg_postinst() {
	elog "If you will be starting mpd via /etc/init.d/mpd, please make"
	elog "sure that MPD's pid_file is set to /var/run/mpd/mpd.pid."

	# also change the homedir if the user has existed before
	usermod -d "/var/lib/mpd" mpd
}
