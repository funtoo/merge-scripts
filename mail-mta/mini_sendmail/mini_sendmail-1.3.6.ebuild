# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit eutils

DESCRIPTION="The simplest implementation of sendmail, simple forwarder to localhost:25. Chroot friendly."
HOMEPAGE="http://www.acme.com/software/mini_sendmail/"
SRC_URI="http://www.acme.com/software/mini_sendmail/mini_sendmail-${PV}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE="vanilla"

DEPEND=""
RDEPEND="${DEPEND}"

src_prepare() {
	use vanilla || epatch "$FILESDIR/mini_sendmail-drop-getlogin.patch"
}

src_install() {
	dobin mini_sendmail || die
	doman mini_sendmail.8 || die
	dodoc README || die
}

pkg_postinst() {
	if use !vanilla; then
		ewarn ""
		ewarn "By default funtoo's mini_sendmail is provided without getlogin() function"
		ewarn "in order to make it working into very limited chroot environment."
		ewarn ""
	fi
}
