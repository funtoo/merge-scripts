# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="manage ssh and GPG keys in a convenient and secure manner. Frontend for ssh-agent/ssh-add"
HOMEPAGE="http://www.funtoo.org/en/security/keychain/intro/"
SRC_URI="http://www.funtoo.org/archive/keychain/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND=""
RDEPEND="app-shells/bash || ( net-misc/openssh net-misc/ssh )"

src_compile() {
	echo
}

src_install() {
	dobin keychain || die "dobin failed"
	doman keychain.1 || die "doman failed"
	dodoc ChangeLog README.rst || die
}

pkg_postinst() {
	einfo "Please see the keychain man page or visit"
	einfo "http://www.funtoo.org/en/security/keychain/intro/"
	einfo "for information on how to use keychain."
}
