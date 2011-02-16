EAPI=2

inherit eutils autotools

DESCRIPTION="Free UPnP Entertainment Service"
HOMEPAGE="http://fuppes.ulrich-voelkel.de/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE="+transcode +imagemagick faad +flac +muse lame +mad +taglib +twolame gnome notify +dlna"

RDEPEND="dlna? ( media-libs/libdlna )
	imagemagick? ( media-gfx/imagemagick )
	transcode? ( media-video/ffmpeg )
	"

DEPEND="${RDEPEND}
	faad? ( media-libs/faad2 )
	flac? ( media-libs/flac )
	gnome? ( gnome-base/gnome-panel )
	virtual/libiconv
	lame? ( media-sound/lame )
	mad? ( media-libs/libmad )
	muse? ( media-sound/musepack-tools )
	notify? ( x11-libs/libnotify )
	taglib? ( media-libs/taglib )
	twolame? ( media-sound/twolame )
	>=dev-db/sqlite-3.2
	dev-libs/libpcre
	dev-libs/libxml2
	"

pkg_setup() {
	enewgroup ${PN}
	enewuser ${PN} -1 -1 -1 ${PN}
}

src_compile() {
	local myconf
	use transcode || myconf="${myconf} --disable-libavformat"
	use gnome && myconf="${myconf} --enable-gnome-panel-applet"
	econf $(use_enable faad) \
		$(use_enable imagemagick magickwand) \
		$(use_enable lame) \
		$(use_enable mad) \
		$(use_enable notify inotify) \
		$(use_enable taglib) \
		$(use_enable twolame) \
		${myconf} || die "configure failed"
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
}

