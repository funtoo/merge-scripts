# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit git autotools

DESCRIPTION="provides a mountable Linux filesystem which transparently compress
its content"
HOMEPAGE="http://miio.net/wordpress/projects/fusecompress/"
SRC_URI=""
EGIT_REPO_URI="git://github.com/tex/fusecompress.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="bzip2 lzma lzo zlib"

DEPEND=">=dev-libs/boost-1.33.1
		bzip2? ( app-arch/bzip2 )
		lzma? ( >=app-arch/xz-utils-4.999.9_beta )
		lzo? ( >=dev-libs/lzo-2 )
		zlib? ( sys-libs/zlib )
"
RDEPEND="${DEPEND}"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf \
	$(use_with bzip2 bz2) \
	$(use_with lzma) \
	$(use_with lzo lzo2) \
	$(use_with zlib z)
	emake || die "Compilation failed"
}
src_install() {
	emake DESTDIR="${D}" install
	dodoc README
}
