# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-misc/pysmssend/pysmssend-1.45.ebuild,v 1.1 2010/05/29 11:47:12 hwoarang Exp $

PYTHON_DEPEND="2:2.5"

EAPI="2"

inherit distutils eutils multilib

DESCRIPTION="Python Application for sending sms over multiple ISPs"
HOMEPAGE="http://pysmssend.silverarrow.org/"
SRC_URI="http://pysmssend.silverarrow.org/files/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="qt4"

RDEPEND=">dev-python/mechanize-0.1.7b
	qt4? ( dev-python/PyQt4[X] )"

src_prepare() {
	python_convert_shebangs -r 2 .
}

src_install() {
	distutils_src_install
	if use qt4; then
		insinto /usr/share/${PN}/Icons || die "insinto failed"
		doins   Icons/* || die "doins failed"
		doicon  Icons/pysmssend.png || die "doicon failed"
		dobin   pysmssend pysmssendcmd || die "failed to create executables"
		make_desktop_entry pysmssend pySMSsend pysmssend \
			"Applications;Network" || die "make_desktop_entry failed"
	else
		dobin   pysmssendcmd || die "failed to create executable"
		dosym   pysmssendcmd /usr/bin/pysmssend || die "dosym failed"
	fi
	dodoc README AUTHORS TODO || die "dodoc failed"
}
