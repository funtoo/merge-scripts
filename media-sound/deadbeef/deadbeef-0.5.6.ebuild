# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit fdo-mime gnome2-utils versionator

MY_PV="$(replace_version_separator 3 '-')"

SRC_URI="mirror://sourceforge/${PN}/${PN}-${MY_PV}.tar.bz2
		 http://sourceforge.net/projects/${PN}/files/${PN}-${MY_PV}.tar.bz2/download -> ${PN}-${MY_PV}.tar.bz2"
KEYWORDS="*"

DESCRIPTION="foobar2k-like music player"
HOMEPAGE="http://deadbeef.sourceforge.net/"

LICENSE="GPL-2
	LGPL-2.1
	ZLIB
	psf? ( BSD XMAME )
	dumb? ( DUMB-0.9.2 )
	shn? ( shorten )"

SLOT="0"

IUSE="adplug aac alac alsa psf ape cdda cover cover-imlib2 dts dumb converter curl ffmpeg flac gme
	hotkeys lastfm m3u midi mms mp3 musepack nls notify nullout oss pulseaudio rpath mono2stereo
	shellexec shn sid sndfile src static supereq threads tta vorbis vtx wavpack zip gtk3 +gtk2"

REQUIRED_USE="
	cover? ( curl )
	lastfm? ( curl )"

LANGS="be bg bn ca cs da de el en_GB eo es et fa fi fr gl he hr hu id it ja kk km lg lt nb nl pl pt
		pt_BR ro ru si sk sl sr sr@latin sv te tr ug uk vi zh_CN zh_TW"
for lang in ${LANGS}; do
	IUSE+=" linguas_${lang}"
done

RDEPEND="aac? ( media-libs/faad2 )
	alsa? ( media-libs/alsa-lib )
	alac? ( media-libs/faad2 )
	cdda? ( >=dev-libs/libcdio-0.90 media-libs/libcddb )
	cover? ( media-libs/imlib2 )
	ffmpeg? ( =virtual/ffmpeg-0.10.3 )
	flac? ( media-libs/flac )
	gtk2? ( x11-libs/gtk+:2 )
	gtk3? ( x11-libs/gtk+:3 )
	notify? ( sys-apps/dbus )
	midi? ( media-sound/timidity-freepats )
	mms? ( media-libs/libmms )
	mp3? ( media-libs/libmad )
	musepack? ( media-sound/musepack-tools )
	pulseaudio? ( media-sound/pulseaudio )
	sndfile? ( media-libs/libsndfile )
	src? ( media-libs/libsamplerate )
	vorbis? ( media-libs/libvorbis )
	wavpack? ( media-sound/wavpack )
	zip? ( dev-libs/libzip
	sys-libs/zlib )
	curl? ( net-misc/curl )"

DEPEND="
	dev-util/intltool
	${RDEPEND}"

S="${WORKDIR}/${PN}-${MY_PV}"

QA_TEXTRELS="usr/lib/deadbeef/ffap.so.0.0.0"

pkg_setup() {
	if use psf || use dumb || use shn && use static ; then
		die "ao/converter/dumb or shn plugins can't be builded statically"
	fi
}

src_prepare() {
	if use ffmpeg ;then
		sed -e 's|libavcodec >= 51.0.0 libavutil libavformat|deadbeef-libavcodec >= 51.0.0 deadbeef-libavutil deadbeef-libavformat|g' \
		-e 's|libavcodec libavutil libavformat|deadbeef-libavcodec deadbeef-libavutil deadbeef-libavformat|g' \
		-i configure
	fi
	if use midi ; then
		# set default gentoo path
		sed -e 's;/etc/timidity++/timidity-freepats.cfg;/usr/share/timidity/freepats/timidity.cfg;g' \
		-i "${S}/plugins/wildmidi/wildmidiplug.c"
	fi

	# remove unity trash
	epatch "${FILESDIR}/desktop.patch"

	for lang in ${LANGS};do
		for x in ${lang};do
			if ! use linguas_${x}; then
				sed -e "s|^${x}$||" -i "po/LINGUAS"
			fi
		done
	done
}

src_configure() {
	my_config="--disable-portable
		--docdir=/usr/share/${PN}
		$(use_enable aac)
		$(use_enable adplug)
		$(use_enable alac)
		$(use_enable alsa)
		$(use_enable ape ffap)
		$(use_enable cdda)
		$(use_enable converter)
		$(use_enable cover artwork)
		$(use_enable cover-imlib2 artwork-imlib2)
		$(use_enable curl vfs-curl)
		$(use_enable dts dca)
		$(use_enable dumb)
		$(use_enable ffmpeg)
		$(use_enable flac)
		$(use_enable gme)
		$(use_enable gtk2)
		$(use_enable gtk3)
		$(use_enable hotkeys)
		$(use_enable lastfm lfm)
		$(use_enable m3u)
		$(use_enable midi wildmidi)
		$(use_enable mms)
		$(use_enable mono2stereo)
		$(use_enable mp3 mad)
		$(use_enable musepack)
		$(use_enable nls)
		$(use_enable notify)
		$(use_enable nullout)
		$(use_enable oss)
		$(use_enable psf)
		$(use_enable pulseaudio pulse)
		$(use_enable rpath)
		$(use_enable shellexec)
		$(use_enable shellexec shellexecui)
		$(use_enable shn)
		$(use_enable sid)
		$(use_enable sndfile)
		$(use_enable src)
		$(use_enable static)
		$(use_enable static staticlink)
		$(use_enable supereq)
		$(use_enable threads)
		$(use_enable tta)
		$(use_enable vorbis)
		$(use_enable vtx)
		$(use_enable wavpack)
		$(use_enable zip vfs-zip)"

	econf ${my_config}
}
pkg_preinst() {
	use linguas_pt_BR || rm -f "${D}/usr/share/deadbeef/help.pt_BR.txt"
	use linguas_ru || rm -f "${D}/usr/share/deadbeef/help.ru.txt"
	gnome2_icon_savelist
	gnome2_schemas_savelist
}

pkg_postinst() {
	if use midi ; then
		einfo "enable manually freepats support for timidity via"
		einfo "eselect timidity set --global freepats"
	fi
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
	gnome2_schemas_update
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
	gnome2_schemas_update
}
