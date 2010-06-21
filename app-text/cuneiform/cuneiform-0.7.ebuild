# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/cuneiform/cuneiform-0.7.ebuild,v 1.1 2009/08/16 15:35:24 pva Exp $

inherit cmake-utils versionator

PV_MAJ=$(get_version_component_range 1-2)
MY_P=${PN}-linux-${PV}

DESCRIPTION="An enterprise quality OCR engine developed in USSR/Russia in the 90's."
HOMEPAGE="https://launchpad.net/cuneiform-linux"
SRC_URI="http://launchpad.net/${PN}-linux/${PV_MAJ}/${PV_MAJ}/+download/${MY_P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="imagemagick debug"

RDEPEND="imagemagick? ( media-gfx/imagemagick )"
DEPEND=">=dev-util/cmake-2.6.2
	${RDEPEND}"

DOCS="readme.txt"

S=${WORKDIR}/${MY_P}

src_unpack(){
	unpack ${A}
	# Fix automagic dependencies / linking
	if ! use imagemagick; then
		sed -e '/pkg_check_modules(MAGICK ImageMagick++)/s/^/#DONOTFIND /' \
			-i "${S}/cuneiform_src/Kern/CMakeLists.txt" \
		|| die "Sed for ImageMagick automagic dependency failed."
	fi
}
