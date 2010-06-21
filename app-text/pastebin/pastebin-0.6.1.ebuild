# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/pastebin/pastebin-0.6.1.ebuild,v 1.1 2010/02/28 18:33:41 jlec Exp $

DESCRIPTION="CLI to pastebin.com"
HOMEPAGE="http://code.google.com/p/pastebin-cli/"
SRC_URI="http://pastebin-cli.googlecode.com/files/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

DEPEND=""
RDEPEND="dev-perl/libwww-perl"

src_install() {
	dobin ${PN} || die
}
