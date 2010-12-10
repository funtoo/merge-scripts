# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit autotools

DESCRIPTION="provides a mountable Linux filesystem which transparently compress
its content"
HOMEPAGE="http://miio.net/wordpress/projects/fusecompress/"
SRC_URI="https://github.com/tex/${PN}/tarball/${PV} -> ${PN}-git-${PV}.tgz"


LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="bzip2 lzma lzo zlib"

DEPEND=">=dev-libs/boost-1.33.1
		bzip2? ( app-arch/bzip2 )
		lzma? ( >=app-arch/xz-utils-4.999.9_beta )
		lzo? ( >=dev-libs/lzo-2 )
		zlib? ( sys-libs/zlib )
"
RDEPEND="${DEPEND}"

src_prepare() {
	# Ugly, but there is no better way to do it.
	cd "${WORKDIR}"/tex-${PN}-*
	S="$(pwd)"

	# Patches from debian's fusecomrpess-2.6-3.
	epatch "${FILESDIR}/2.6-fix-manpages.patch"
	epatch "${FILESDIR}/2.6_Fix-compilation-failing-with-new-boost-library.patch"
	epatch "${FILESDIR}/2.6_build-failure-with-new-lzma.patch"
	epatch "${FILESDIR}/2.6_fix-build-error-on-64bit.patch"
	epatch "${FILESDIR}/2.6_fix-build-failure-with-boost-140.patch"
	epatch "${FILESDIR}/2.6_fix-build-failure-with-gcc44.patch"

	eautoreconf
}

src_configure() {
	econf \
	$(use_with bzip2 bz2) \
	$(use_with lzma) \
	$(use_with lzo lzo2) \
	$(use_with zlib z)
}
src_install() {
	emake DESTDIR="${D}" install
	dodoc README
}
