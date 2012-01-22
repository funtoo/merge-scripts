# Copyright 2012 Funtoo Technologies
# Distributed under the terms of the GNU General Public License v2

EAPI=4

MODULE_AUTHOR=AGRUNDMA
MODULE_VERSION=0.08
inherit perl-module

DESCRIPTION="Fast, high-quality fixed-point image resizing"

SLOT="0"
KEYWORDS="*"
IUSE="gif"

RDEPEND="media-libs/libjpeg-turbo >=media-libs/libpng-1.4 gif? ( media-libs/giflib )"
DEPEND="${RDEPEND} >=virtual/perl-Module-Build-0.28"

src_prepare() {
	cd $S
	cat ${FILESDIR}/libpng-1.5-memcpy.patch | patch -p0 || die
	perl-module_src_prepare
}
