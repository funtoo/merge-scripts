# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/musepack-tools/musepack-tools-458.ebuild,v 1.5 2010/03/05 22:49:54 ssuominen Exp $

inherit cmake-utils

# svn co http://svn.musepack.net/libmpc/trunk musepack-tools-${PV}
# find ./musepack-tools-${PV} -type d -name .svn | xargs rm -rf
# tar -cjf musepack-tools-${PV}.tar.bz2 musepack-tools-${PV}

DESCRIPTION="Musepack SV8 libraries and utilities"
HOMEPAGE="http://www.musepack.net"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="BSD LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ppc ~ppc64 ~x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE=""

DEPEND=">=media-libs/libcuefile-${PV}
	>=media-libs/libreplaygain-${PV}
	!media-libs/libmpcdec
	!media-libs/libmpcdecsv7"

PATCHES=( "${FILESDIR}/${P}-gentoo.patch" )
