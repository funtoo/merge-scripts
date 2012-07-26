# Distributed under the terms of the GNU General Public License v2

EAPI="2"

DESCRIPTION="A portable user-space implementation of the NFSv3 server specification"
HOMEPAGE="http://unfs3.sourceforge.net"
SRC_URI="http://downloads.sourceforge.net/project/unfs3/unfs3/0.9.22/unfs3-0.9.22.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="cluster"
RDEPEND="net-nds/rpcbind"

src_configure() {
	econf $(use_enable cluster)
}

src_compile() {
	emake -j1
}

src_install() {
	make DESTDIR="${D}" install
	newinitd ${FILESDIR}/unfsd.init unfsd
}
