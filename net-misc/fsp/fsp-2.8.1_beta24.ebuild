# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

MY_PV=${PV/_beta/b}

S="${WORKDIR}/${PN}-${MY_PV}"

DESCRIPTION="File Service Protocol - What Anonymous FTP should be!"
HOMEPAGE="http://fsp.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${PN}-${MY_PV}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND=""
RDEPEND=""

src_install()
{
	emake DESTDIR=${D} install || die "Install failed."
}
