# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/jack-audio-connection-kit/jack-audio-connection-kit-0.121.3.ebuild,v 1.14 2012/07/15 17:57:38 armin76 Exp $

EAPI=2

inherit flag-o-matic eutils multilib multilib

DESCRIPTION="A low-latency audio server"
HOMEPAGE="http://www.jackaudio.org"
SRC_URI="http://www.jackaudio.org/downloads/${P}.tar.gz"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="*"
IUSE="3dnow altivec alsa coreaudio doc debug examples mmx oss sse cpudetection pam"

RDEPEND=">=media-libs/libsndfile-1.0.0
	sys-libs/ncurses
	alsa? ( >=media-libs/alsa-lib-1.0.18 )
	dev-python/dbus-python
	media-libs/libsamplerate
	!media-sound/jack-cvs"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( app-doc/doxygen )"
RDEPEND="${RDEPEND}
	pam? ( sys-auth/realtime-base )"

src_prepare() {
	epatch "${FILESDIR}/${PN}-sparc-cpuinfo.patch"
	epatch "${FILESDIR}/${PN}-freebsd.patch"
}

src_configure() {
	local myconf=""

	# CPU Detection (dynsimd) uses asm routines which requires 3dnow, mmx and sse.
	if use cpudetection && use 3dnow && use mmx && use sse ; then
		einfo "Enabling cpudetection (dynsimd). Adding -mmmx, -msse, -m3dnow and -O2 to CFLAGS."
		myconf="${myconf} --enable-dynsimd"
		append-flags -mmmx -msse -m3dnow -O2
	fi

	use doc || export ac_cv_prog_HAVE_DOXYGEN=false

	econf \
		$(use_enable altivec) \
		$(use_enable alsa) \
		$(use_enable coreaudio) \
		$(use_enable debug) \
		$(use_enable mmx) \
		$(use_enable oss) \
		--disable-portaudio \
		$(use_enable sse) \
		--with-html-dir=/usr/share/doc/${PF} \
		--disable-dependency-tracking \
		${myconf} || die "configure failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"
	dodoc AUTHORS TODO README

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r "${S}/example-clients"
	fi
}
