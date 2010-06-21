# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

DESCRIPTION="recover deleted files on an ext3 file system"
HOMEPAGE="http://www.xs4all.nl/~carlo17/howto/undelete_ext3.html"
SRC_URI="http://ext3grep.googlecode.com/files/${P}.tar.gz"

LICENSE="GPL-2"

SLOT="0"
KEYWORDS="~x86"

IUSE="debug largefile libcwd mmap pch"
RDEPEND=""
DEPEND="${RDEPEND}
	debug? ( libcwd? ( dev-cpp/libcwd ) )"

src_unpack(){
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/gcc-4.3.patch
}

src_compile() {
	local myconf

	use debug && myconf="--disable-optimize"

	econf \
		$(use_enable libcwd) \
		$(use_enable debug) \
		${myconf} \
		$(use_enable pch) \
		$(use_enable largefile) \
		$(use_enable mmap)

	emake || die "emake failed"
}


src_install() {
	emake DESTDIR="${D}" install || die

	dodoc NEWS README || die
}
