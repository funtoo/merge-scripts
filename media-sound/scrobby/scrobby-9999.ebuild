# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2

inherit eutils autotools git

DESCRIPTION="An Audioscrobbler MPD client"
HOMEPAGE="http://unkart.ovh.org/scrobby"
EGIT_REPO_URI="git://repo.or.cz/scrobby.git"
LICENSE="GPL-2"
IUSE=""

SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"

DEPEND="dev-libs/openssl
	net-misc/curl"
RDEPEND="${DEPEND}
	dev-util/pkgconfig"

src_prepare() {
	eautoreconf
}

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
