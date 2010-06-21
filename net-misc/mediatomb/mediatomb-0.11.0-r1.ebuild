# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/mediatomb/mediatomb-0.11.0.ebuild,v 1.6 2008/10/25 22:02:27 pvdabeel Exp $

inherit eutils autotools

DESCRIPTION="MediaTomb is an open source UPnP MediaServer"
HOMEPAGE="http://www.mediatomb.cc/"
SRC_URI="mirror://sourceforge/mediatomb/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="+curl debug +exif +expat +ffmpeg +javascript libextractor mysql +taglib"
RDEPEND="
	mysql? ( virtual/mysql )
	!mysql? ( >=dev-db/sqlite-3 )
	javascript? ( dev-lang/spidermonkey )
	expat? ( dev-libs/expat )
	taglib? ( media-libs/taglib )
	!taglib? ( media-libs/id3lib )
	exif? ( media-libs/libexif )
	libextractor? ( media-libs/libextractor )
	ffmpeg? ( media-video/ffmpeg )
	curl? ( net-misc/curl )
	sys-apps/file
	sys-libs/zlib
	virtual/libiconv"
DEPEND="${RDEPEND}"

MEDIATOMB_HOMEDIR="/var/lib/mediatomb"
MEDIATOMB_CONFDIR="/etc/mediatomb"
MEDIATOMB_PIDDIR="/var/run/mediatomb"

pkg_setup() {
	# disable libextractor support if ffmpeg and libextractor use are enabled
	if use ffmpeg && use libextractor; then
		ewarn "ffmpeg and libextractor USE flags are enabled. libextractor support will be disabled."
	fi

	# create the mediatomb group and user
	enewgroup mediatomb
	enewuser mediatomb -1 -1 /dev/null mediatomb
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch "${FILESDIR}/${P}-newffmpeg.patch" 
	epatch "${FILESDIR}/${P}+curl-7.18.patch" 
	epatch "${FILESDIR}/${P}-ps3-pcm.patch" 
	eautoreconf
}

src_compile() {
	local myconf

	# disable libextractor support if ffmpeg and libextractor use are enabled
	if use ffmpeg && use libextractor; then
		myconf="${myconf} --enable-ffmpeg --disable-libextractor"
	else
		myconf="${myconf} $(use_enable ffmpeg) $(use_enable libextractor)"
	fi

	econf \
		--prefix=/usr \
		$(use_enable curl) \
		$(use_enable debug tombdebug) \
		$(use_enable exif libexif) \
		$(use_enable expat) \
		$(use_enable javascript libjs) \
		$(use_enable mysql) $(use_enable !mysql sqlite3) \
		$(use_enable taglib) $(use_enable !taglib id3lib) \
		--enable-external-transcoding \
		--enable-libmagic \
		--enable-protocolinfo-extension \
		${myconf} \
		|| die "Configure failed!"

	emake || die "Make failed!"
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed!"

	dodoc AUTHORS ChangeLog NEWS README TODO

	sed -e "s:#MYSQL#:$(use mysql && echo "mysql"):" \
		"${FILESDIR}/${PN}.initd" \
		> "${T}/mediatomb.initd"
	newinitd "${T}/mediatomb.initd" mediatomb
	newconfd "${FILESDIR}/${PN}.confd" mediatomb

	insinto "${MEDIATOMB_CONFDIR}"
	newins "${FILESDIR}/${P}.config" config.xml
	fperms 0600 "${MEDIATOMB_CONFDIR}/config.xml"
	fowners mediatomb:mediatomb "${MEDIATOMB_CONFDIR}/config.xml"

	keepdir "${MEDIATOMB_HOMEDIR}"
	fowners mediatomb:mediatomb "${MEDIATOMB_HOMEDIR}"

	keepdir "${MEDIATOMB_PIDDIR}"
	fowners mediatomb:mediatomb "${MEDIATOMB_PIDDIR}"
}

pkg_postinst() {
	if use mysql; then
		elog "MediaTomb has been built with MySQL support. Please"
		elog "consult sections 4.2.2 and 6.1 of the MediaTomb"
		elog "documentation for information on configuring MediaTomb"
		elog "with MySQL. http://mediatomb.cc/pages/documentation"
		elog
	fi

	elog "The MediaTomb Web UI can be reached at:"
	elog "http://localhost:49152/"
	elog
	elog "To start MediaTomb:"
	elog "/etc/init.d/mediatomb start"
	elog
	elog "To start MediaTomb at boot:"
	elog "rc-update add mediatomb default"
}
