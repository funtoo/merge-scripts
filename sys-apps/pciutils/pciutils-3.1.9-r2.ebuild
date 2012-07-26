# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit eutils multilib toolchain-funcs

DESCRIPTION="Various utilities dealing with the PCI bus"
HOMEPAGE="http://atrey.karlin.mff.cuni.cz/~mj/pciutils.html"
SRC_URI="ftp://atrey.karlin.mff.cuni.cz/pub/linux/pci/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="static-libs zlib"

DEPEND="zlib? ( sys-libs/zlib )"
RDEPEND="${DEPEND}
	sys-apps/hwids"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-3.1.7-install-lib.patch #273489
	epatch "${FILESDIR}"/${PN}-3.1.7-fbsd.patch #262321

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
		PCI_COMPRESSED_IDS=0 \
		PCI_IDS=pci.ids \
		LIBDIR="\${PREFIX}/$(get_libdir)" \
		"$@"
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
	use static-libs && dolib.a "${S}.static/lib/libpci.a"
	dodoc ChangeLog README TODO

	rm "${D}"/usr/bin/update-pciids "${D}"/usr/share/misc/pci.ids \
		"${D}"/usr/share/man/man8/update-pciids.8*

	newinitd "${FILESDIR}"/init.d-pciparm pciparm
	newconfd "${FILESDIR}"/conf.d-pciparm pciparm
}

pkg_postinst() {
	elog "The 'pcimodules' program has been replaced by 'lspci -k'"
	elog ""
	elog "The 'network-cron' USE flag is gone; if you want a more up-to-date"
	elog "pci.ids file, you should use sys-apps/hwids-99999999 (live ebuild)."
}
