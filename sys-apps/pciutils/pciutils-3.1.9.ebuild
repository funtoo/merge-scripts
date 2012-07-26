# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit eutils multilib toolchain-funcs

DESCRIPTION="Various utilities dealing with the PCI bus"
HOMEPAGE="http://atrey.karlin.mff.cuni.cz/~mj/pciutils.html"
SRC_URI="ftp://atrey.karlin.mff.cuni.cz/pub/linux/pci/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~*"
IUSE="network-cron static-libs zlib"

DEPEND="zlib? ( sys-libs/zlib )"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-3.1.7-install-lib.patch #273489
	epatch "${FILESDIR}"/${PN}-3.1.7-fbsd.patch #262321
	epatch "${FILESDIR}"/${PN}-3.1.8-avoid-segfault-on-init.patch
	if use static-libs ; then
		cp -pPR "${S}" "${S}.static" || die
	fi
}

pemake() {
	emake \
		HOST="${CHOST}" \
		CROSS_COMPILE="${CHOST}-" \
		CC="$(tc-getCC)" \
		DNS="yes" \
		IDSDIR='$(SHAREDIR)/misc' \
		MANDIR='$(SHAREDIR)/man' \
		PREFIX="${EPREFIX}/usr" \
		SHARED="yes" \
		STRIP="" \
		ZLIB=$(usex zlib) \
		LIBDIR="\${PREFIX}/$(get_libdir)" \
		"$@" || die
}

src_compile() {
	pemake OPT="${CFLAGS}" all
	if use static-libs ; then
		pemake \
			-C "${S}.static" \
			OPT="${CFLAGS}" \
			SHARED="no" \
			lib/libpci.a
	fi
}

src_install() {
	pemake DESTDIR="${D}" install install-lib
	use static-libs && { dolib.a "${S}.static/lib/libpci.a" || die ; }
	dodoc ChangeLog README TODO

	if use network-cron ; then
		exeinto /etc/cron.monthly
		newexe "${FILESDIR}"/pciutils.cron update-pciids \ || die "Failed to update cronjob"
	fi

	newinitd "${FILESDIR}"/init.d-pciparm pciparm
	newconfd "${FILESDIR}"/conf.d-pciparm pciparm
}

pkg_postinst() {
	elog "The 'pcimodules' program has been replaced by 'lspci -k'"
}
