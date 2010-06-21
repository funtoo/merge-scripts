# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=1

WANT_AUTOCONF=latest
WANT_AUTOMAKE=latest

inherit eutils autotools subversion

ESVN_REPO_URI="http://svn.mediatomb.cc/svnroot/mediatomb/trunk/mediatomb"

DESCRIPTION="MediaTomb is an open source UPnP MediaServer"
HOMEPAGE="http://www.mediatomb.cc/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="debug dvd +exif +ffmpeg ffmpegthumbnailer inotify +javascript +mp4 mysql +taglib"

RDEPEND="
	mysql? ( virtual/mysql )
	!mysql? ( >=dev-db/sqlite-3 )
	javascript? ( dev-lang/spidermonkey )
	dev-libs/expat
	taglib? ( media-libs/taglib )
	!taglib? ( media-libs/id3lib )
	dvd? ( >=media-libs/libdvdnav-4 )
	exif? ( media-libs/libexif )
	mp4? ( media-libs/libmp4v2 )
	ffmpeg? ( media-video/ffmpeg )
	ffmpegthumbnailer? ( media-video/ffmpegthumbnailer )
	net-misc/curl
	sys-apps/file
	sys-libs/zlib
	virtual/libiconv"
DEPEND="${RDEPEND}"

MEDIATOMB_HOMEDIR="/var/lib/mediatomb"
MEDIATOMB_CONFDIR="/etc/mediatomb"

pkg_setup() {
	if use inotify && [ -e /proc/config.gz ] && [ "`cat /proc/config.gz | gzip -d | grep CONFIG_INOTIFY=`" != "CONFIG_INOTIFY_USER=yes" ]
		then
			ewarn "Please enable Inotify support in your kernel, found at:"
			ewarn
			ewarn "  File systems --->"
			ewarn "    [*] Inotify file change notification support"
			ewarn "    [*]   Inotify support for userspace"
	fi
	enewgroup mediatomb
	enewuser mediatomb -1 -1 /dev/null mediatomb
}

src_unpack() {
	subversion_src_unpack
	eautoreconf
}

src_compile() {
	if use ffmpegthumbnailer; then
		myconf="${myconf} --enable-ffmpegthumbnailer --enable-ffmpeg"
	else
		myconf="${myconf} $(use_enable ffmpegthumbnailer) $(use_enable ffmpeg)"
	fi

	econf \
		--prefix=/usr \
		$(use_enable debug tombdebug) \
		$(use_enable dvd libdvdnav) \
		$(use_enable exif libexif) \
		$(use_enable inotify) \
		$(use_enable javascript libjs) \
		$(use_enable mp4 libmp4v2) \
		$(use_enable mysql) $(use_enable !mysql sqlite3) \
		$(use_enable taglib) $(use_enable !taglib id3lib) \
		--enable-atrailers \
		--enable-curl \
		--enable-external-transcoding \
		--enable-libmagic \
		--enable-protocolinfo-extension \
		--enable-weborama \
		--enable-youtube \
		--enable-zlib \
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
