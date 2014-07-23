# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils flag-o-matic toolchain-funcs

DESCRIPTION="Snort plugin that allows automated blocking of IP addresses on several firewalls"
HOMEPAGE="http://www.snortsam.net/"
SRC_URI="${HOMEPAGE}files/snortsam/${PN}-src-${PV}.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~*"
IUSE="debug"

S=${WORKDIR}/${PN}

src_prepare() {
	epatch "${FILESDIR}"/${P}-gentoo.patch
	
	# From Funtoo:
	# 	https://bugs.funtoo.org/browse/FL-1408
	epatch "${FILESDIR}"/${P}-fix-undefined-reference.patch

	find "${S}" -depth -type d -name CVS -exec rm -rf \{\} \;
}

src_configure() {
	use debug && append-cflags -DFWSAMDEBUG
	tc-export CC
}

src_compile() {
	sh makesnortsam.sh || die
}

src_install() {
	dobin snortsam
	find "${S}" -depth -type f -name "*.asc" -exec rm -f {} \;
	dodoc docs/* conf/*
}

pkg_postinst() {
	elog
	elog "To use snortsam with snort, you'll have to compile snort with USE=snortsam."
	elog "Read the INSTALL file to configure snort for snortsam, and configure"
	elog "snortsam for your particular firewall."
	elog
}
