# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils flag-o-matic

DESCRIPTION="Squeezelite is a small headless Squeezebox emulator for Linux using ALSA audio output"
HOMEPAGE="https://code.google.com/p/squeezelite"
SRC_URI="https://squeezelite.googlecode.com/archive/866fcc7c7e14f354da27fd64f50069e762abd835.zip"
S="${WORKDIR}/squeezelite-866fcc7c7e14"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="flac vorbis mp3 aac"

DEPEND="media-libs/alsa-lib
		flac? ( media-libs/flac )
		vorbis? ( media-libs/libvorbis )
		mp3? ( media-libs/libmad )
		aac? ( media-libs/faad2 )
"
RDEPEND="${DEPEND}
		 media-sound/alsa-utils"

pkg_setup() {
	# Create the user and group if not already present
	enewuser squeezelite -1 -1 "/dev/null" audio
}

src_prepare () {
	# Apply patches
	epatch "${FILESDIR}/${P}-gentoo-makefile.patch"
	epatch "${FILESDIR}/${P}-gentoo-optional-codecs.patch"
}

src_compile() {

	# Configure optional codec support; this is added to the original
	# source via a patch in this ebuild at present.
	if ! use flac; then
		append-cppflags "-DSL_NO_FLAC"
		einfo "FLAC support disabled; add 'flac' USE flag if you need it"
	fi
	if ! use vorbis; then
		append-cppflags "-DSL_NO_OGG"
		einfo "Ogg/Vorbis support disabled; add 'vorbis' USE flag if you need it"
	fi
	if ! use mp3; then
		append-cppflags "-DSL_NO_MP3"
		einfo "MP3 support disabled; add 'mp3' USE flag if you need it"
	fi
	if ! use aac; then
		append-cppflags "-DSL_NO_AAC"
		einfo "AAC support disabled; add 'aac' USE flag if you need it"
	fi

	# Build it
	emake || die "emake failed"
}

src_install() {
	dobin squeezelite
	dodoc LICENSE.txt

	newconfd "${FILESDIR}/${PN}.conf.d" "${PN}"
	newinitd "${FILESDIR}/${PN}.init.d" "${PN}"
}

pkg_postinst() {
	# Provide some post-installation tips.
	elog "If you want start Squeezelite automatically on system boot:"
	elog "  rc-update add squeezelite default"
	elog "Edit /etc/cond.d/squeezelite to customise -- in particular"
	elog "you may want to set the audio device to be used."
}
