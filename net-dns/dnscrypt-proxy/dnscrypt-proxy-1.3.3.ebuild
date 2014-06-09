# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils flag-o-matic user

DESCRIPTION="A tool for securing communications between a client and a DNS resolver"
HOMEPAGE="http://dnscrypt.org/"
SRC_URI="http://download.dnscrypt.org/${PN}/${P}.tar.gz"
RESTRICT="mirror"

LICENSE="ISC"
SLOT="0"
KEYWORDS="*"
IUSE=""
RDEPEND="dev-libs/libsodium"

pkg_setup() {
	enewgroup dnscrypt
	enewuser dnscrypt -1 -1 /var/empty dnscrypt
}

src_configure() {
	if [[ ! -e configure ]] ; then
		./autogen.sh || die "autogen failed"
	fi
	append-ldflags -Wl,-z,noexecstack
	econf --enable-nonblocking-random
}

src_install() {
	default
	newinitd "${FILESDIR}/${PN}.initd" ${PN}
	newconfd "${FILESDIR}/${PN}.confd" ${PN}
	dodoc {AUTHORS,COPYING,INSTALL,NEWS,README,README.markdown,TECHNOTES,THANKS}
}
