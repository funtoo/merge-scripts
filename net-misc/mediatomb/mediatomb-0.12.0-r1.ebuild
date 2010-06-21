# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/mediatomb/mediatomb-0.12.0-r1.ebuild,v 1.2 2010/04/04 04:44:20 darkside Exp $

EAPI=2

inherit eutils linux-info

DESCRIPTION="MediaTomb is an open source UPnP MediaServer"
HOMEPAGE="http://www.mediatomb.cc/"
SRC_URI="mirror://sourceforge/mediatomb/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE="debug +exif +ffmpeg inotify +javascript lastfm +mp4 mysql +taglib thumbnail"

DEPEND="
	mysql? ( virtual/mysql )
	!mysql? ( >=dev-db/sqlite-3 )
	javascript? ( dev-lang/spidermonkey )
	dev-libs/expat
	taglib? ( media-libs/taglib )
	!taglib? ( media-libs/id3lib )
	lastfm? ( >=media-libs/lastfmlib-0.4 )
	exif? ( media-libs/libexif )
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
		if linux_config_exists; then
			if ! linux_chkconfig_present INOTIFY_USER; then
				ewarn "Please enable Inotify support in your kernel:"
				ewarn
				ewarn "  File systems --->"
				ewarn "    [*] Inotify support for userspace"
				ewarn
			fi
		fi
	fi
	enewgroup mediatomb
	enewuser mediatomb -1 -1 /dev/null mediatomb
}

src_configure() {
	if use thumbnail; then
		myconf="${myconf} --enable-ffmpegthumbnailer --enable-ffmpeg"
	else
		myconf="${myconf} $(use_enable thumbnail ffmpegthumbnailer) $(use_enable ffmpeg)"
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
		"${FILESDIR}/${P}.initd" > "${T}/mediatomb.initd" || die
	newinitd "${T}/mediatomb.initd" mediatomb || die
	newconfd "${FILESDIR}/${P}.confd" mediatomb || die

	insinto /etc/mediatomb
	newins "${FILESDIR}/${P}.config" config.xml || die
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
	elog "To start MediaTomb:"
	elog "/etc/init.d/mediatomb start"
	elog
	elog "To start MediaTomb at boot:"
	elog "rc-update add mediatomb default"
	elog
	elog "The MediaTomb web interface can be reached at:"
	elog "http://localhost:49152/"
}
