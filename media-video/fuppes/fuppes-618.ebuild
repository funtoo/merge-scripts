# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: .../media-video/fuppes/fuppes-618.ebuild $

inherit eutils

DESCRIPTION="Free UPnP Entertainment Service."
HOMEPAGE="http://fuppes.sf.net/"
SRC_URI="mirror://sourceforge/fuppes/${PN}-SVN-${PVR}.tar.gz"

S="${WORKDIR}/${PN}-SVN-${PVR}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="+transcode +imagemagick +flac +muse iconv lame +taglib +twolame gnome notify +dlna"

RDEPEND="transcode? ( media-video/ffmpeg[xvid,x264,encode] )
	transcode? ( || ( media-sound/twolame media-sound/lame ) )
	dlna?		( media-libs/libdlna )
	imagemagick? 	( media-gfx/imagemagick )"

DEPEND="${RDEPEND}
	iconv?		( virtual/libiconv )
	lame?		( media-sound/lame )
	muse?		( media-libs/libmpcdec )
	twolame? 	( media-sound/twolame )
	flac?		( media-libs/flac )
	gnome? 		( gnome-base/gnome-panel )
	notify?		( x11-libs/libnotify )
	taglib? 	( media-libs/taglib )
	>=dev-db/sqlite-3.2
	dev-libs/libpcre
	dev-libs/libxml2
	sys-devel/autoconf"

pkg_setup() {
	# Add the fuppes user to make the default config
	# work out-of-the-box
	enewgroup ${PN}
	enewuser ${PN} -1 -1 -1 ${PN}
}
src_unpack() {
        unpack ${A}

        cd "${S}"

        # fix broken configure script
#        epatch "${FILESDIR}/configure-618.patch"
#        epatch "${FILESDIR}/adjust-ffmpeg-path-618.patch"
#        epatch "${FILESDIR}/update_includes-618.patch"
#        epatch "${FILESDIR}/bug-relloc-618.patch"
}

src_compile() {
	local myconf

	if use transcode; then
		myconf="--enable-video-transcoding"
	else
	# If media-video/ffmpeg is not installed, then disable transcode and libavformat
	# checking otherwise, package won't compile properly.
		myconf="--disable-transcoding --disable-libavformat"
	fi

	if use gnome; then
		myconf="${myconf} --enable-gnome-panel-applet"
	fi

	econf 	$(use_enable iconv) \
		$(use_enable lame) \
		$(use_enable twolame) \
		$(use_enable imagemagick) \
		$(use_enable notify) \
		$(use_enable taglib) \
		${myconf} \
		|| die "configure failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed"
	newinitd ${FILESDIR}/fuppes-init fuppes

	keepdir /var/lib/${PN}
	keepdir /var/log/${PN}

	# Filename of sample cfg - use live filename if available
	local sample=${PN}.cfg
	[[ -e "${ROOT}/etc/${PN}/${sample}" ]] && sample="${sample}.sample"
	insinto /etc/${PN}
	insopts -m 0664 -o root -g ${PN}
	newins "${FILESDIR}/${PN}.cfg.sample" "${sample}" || die "sample fuppes.cfg install failed"

	# Filename of sample vfolder.cfg 
	insinto /etc/${PN}
	insopts -m 0664 -o root -g ${PN}
	newins "vfolder.cfg" "vfolder.cfg.sample" || die "sample vfolder.cfg install failed"
}

pkg_postinst() {
	chown ${PN}:${PN} /var/lib/${PN}
	chown ${PN}:${PN} /var/log/${PN}

	einfo "This package includes an init.d file to start the fuppes daemon"
	einfo "You may add this script to your default runlevels as follows:"
	einfo "rc-update add fuppes default"
	einfo "A new user & group has been added to the system for fuppes to run as"
}
