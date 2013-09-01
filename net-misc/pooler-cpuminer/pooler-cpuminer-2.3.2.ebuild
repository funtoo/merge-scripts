# Copyright 2008-2012 Funtoo Technologies

EAPI=5
inherit eutils

DESCRIPTION="Pooler's multi-threaded CPU miner for Litecoin and Bitcoin, fork of Jeff Garzik's reference cpuminer"
HOMEPAGE="https://github.com/pooler/cpuminer/"
SRC_URI="https://sourceforge.net/projects/cpuminer/files/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="net-misc/curl"
RDEPEND="${DEPEND}"

MY_P="cpuminer-${PV}"
S=${WORKDIR}/${MY_P}

src_install() {
	make DESTDIR="${D}" install
	newconfd ${FILESDIR}/minerd.confd minerd
	newinitd ${FILESDIR}/minerd.initd minerd
}
