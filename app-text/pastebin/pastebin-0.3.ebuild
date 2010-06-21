# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

DESCRIPTION="CLI to pastebin.com"
HOMEPAGE="http://code.google.com/p/pastebin-cli/"
SRC_URI="http://pastebin-cli.googlecode.com/files/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

RDEPEND="dev-lang/perl
	dev-perl/libwww-perl"

src_install() {
	dobin ${PN} || die
}
