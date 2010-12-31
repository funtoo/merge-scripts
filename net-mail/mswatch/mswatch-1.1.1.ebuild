# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

DESCRIPTION="mswatch is a command line unix program that keeps two mailboxes
synchronized more efficiently and with shorter delays than periodically
synchronizing the two mailboxes."
HOMEPAGE="http://mswatch.sourceforge.net/"
SRC_URI="mirror://sourceforge/mswatch/mswatch-1.1.1.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="x86 amd64"

src_install() {
	make DESTDIR=${D} install
}
