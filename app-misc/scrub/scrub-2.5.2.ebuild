# Distributed under the terms of the GNU General Public License v2

EAPI="4"
inherit eutils

DESCRIPTION="write patterns on disk/file"
HOMEPAGE="http://code.google.com/p/diskscrub/"
SRC_URI="http://diskscrub.googlecode.com/files/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND=""
RDEPEND=""

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.5.2-return.patch
}

