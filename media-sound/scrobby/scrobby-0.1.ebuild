# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit eutils

DESCRIPTION="An Audioscrobbler MPD client"
HOMEPAGE="http://unkart.ovh.org/scrobby"
SRC_URI="http://unkart.ovh.org/${PN}/${P}.tar.bz2"
LICENSE="GPL-2"
IUSE=""

SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"

DEPEND="dev-libs/openssl
	net-misc/curl"
RDEPEND="${DEPEND}"

src_install() {
	make install DESTDIR="${D}" docdir="${ROOT}/usr/share/doc/${PF}" \
		|| die "install failed"
	newinitd "${FILESDIR}"/scrobby.init scrobby
	prepalldocs
}

pkg_postinst() {
	elog "Example configuration file has been installed at"
	elog "${ROOT}usr/share/doc/${PF}"
	echo
	elog "You can start scrobby by typing:"
	echo
	elog "/etc/init.d/scrobby start"
	echo
}
