# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/mediatomb/mediatomb-0.12.1.ebuild,v 1.3 2010/04/18 12:29:11 maekke Exp $

EAPI=2
inherit eutils linux-info

DESCRIPTION="MediaTomb is an open source UPnP MediaServer"
HOMEPAGE="http://www.mediatomb.cc/"
SRC_URI="mirror://sourceforge/mediatomb/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm x86"
IUSE="debug +exif +ffmpeg inotify +javascript lastfm libextractor +mp4 mysql +taglib thumbnail"

DEPEND="
	mysql? ( virtual/mysql )
	!mysql? ( >=dev-db/sqlite-3 )
	javascript? ( dev-lang/spidermonkey )
	dev-libs/expat
	taglib? ( media-libs/taglib )
	!taglib? ( media-libs/id3lib )
	lastfm? ( >=media-libs/lastfmlib-0.4 )
	exif? ( media-libs/libexif )
	libextractor? ( media-libs/libextractor )
	mp4? ( media-libs/libmp4v2 )
	ffmpeg? ( media-video/ffmpeg )
	thumbnail? ( media-video/ffmpegthumbnailer[jpeg] )
	net-misc/curl
	sys-apps/file
	sys-libs/zlib
	virtual/libiconv"
RDEPEND="${DEPEND}"

pkg_setup() {
	if use inotify; then
		if ! linux_config_exists \
			|| ! linux_chkconfig_present INOTIFY_USER; then
			ewarn "Please enable Inotify support in your kernel:"
			ewarn
			ewarn "  File systems --->"
			ewarn "    [*] Inotify support for userspace"
			ewarn
		fi
	fi
	enewgroup mediatomb
	enewuser mediatomb -1 -1 /dev/null mediatomb
}

src_configure() {
	if use thumbnail; then
		elog "libextrator does not work with thumbnail, disabling libextrator"
		myconf="${myconf} --enable-ffmpegthumbnailer --enable-ffmpeg --disable-libextractor"
	elif ! use thumbnail && use ffmpeg && use libextractor; then
		elog "libextrator does not work with ffmpeg, disabling libextrator"
		myconf="${myconf} --disable-ffmpegthumbnailer --enable-ffmpeg --disable-libextractor"
	else
		myconf="${myconf} $(use_enable thumbnail ffmpegthumbnailer) $(use_enable ffmpeg) $(use_enable libextractor)"
	fi

	econf \
		$(use_enable debug tombdebug) \
		$(use_enable exif libexif) \
		$(use_enable inotify) \
		$(use_enable javascript libjs) \
		$(use_enable lastfm lastfmlib) \
		$(use_enable mp4 libmp4v2) \
		$(use_enable mysql) $(use_enable !mysql sqlite3) \
		$(use_enable taglib) $(use_enable !taglib id3lib) \
		--enable-curl \
		--enable-external-transcoding \
		--enable-libmagic \
		--enable-protocolinfo-extension \
		--enable-youtube \
		--enable-zlib \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed!"

	dodoc AUTHORS ChangeLog NEWS README TODO

	sed -e "s:#MYSQL#:$(use mysql && has_version dev-db/mysql[-minimal] && echo "mysql"):" \
		"${FILESDIR}/${PN}-0.12.0.initd" > "${T}/mediatomb.initd" || die
	newinitd "${T}/mediatomb.initd" mediatomb || die
	newconfd "${FILESDIR}/${PN}-0.12.0.confd" mediatomb || die

	insinto /etc/mediatomb
	newins "${FILESDIR}/${PN}-0.12.0.config" config.xml || die
	fperms 0600 /etc/mediatomb/config.xml
	fowners mediatomb:mediatomb /etc/mediatomb/config.xml

	keepdir /var/lib/mediatomb
	fowners mediatomb:mediatomb /var/lib/mediatomb
}

pkg_postinst() {
	if use mysql; then
		elog "MediaTomb has been built with MySQL support and needs"
		elog "to be configured before being started."
		elog "For more information, please consult the MediaTomb"
		elog "documentation: http://mediatomb.cc/pages/documentation"
		elog
	fi

	elog "To configure MediaTomb edit:"
	elog "/etc/mediatomb/config.xml"
	elog
	elog "The MediaTomb web interface can be reached at (after the service is started):"
	elog "http://localhost:49152/"
}
