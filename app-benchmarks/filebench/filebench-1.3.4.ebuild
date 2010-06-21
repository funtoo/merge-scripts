# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-benchmarks/filebench/filebench-1.3.4.ebuild,v 1.1 2009/03/08 16:04:17 patrick Exp $

inherit eutils autotools

DESCRIPTION="Filebench - A Model Based File System Workload Generator"
HOMEPAGE="http://sourceforge.net/projects/filebench/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="CDDL"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="dev-libs/libaio
	sys-devel/flex
	sys-devel/bison"
RDEPEND=""

src_unpack() {
	unpack ${A}
	cd "${S}"
	#epatch "${FILESDIR}/linux-port.patch"
	eautoreconf
}

src_compile() {
	econf
	emake -j1 || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "Install failed"

	dodoc README AUTHORS docs/README.benchpoint
}
