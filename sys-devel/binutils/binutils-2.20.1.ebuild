# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/binutils/binutils-2.20.1.ebuild,v 1.1 2010/03/08 04:41:09 vapier Exp $

PATCHVER="1.0"
ELF2FLT_VER=""
inherit toolchain-binutils

KEYWORDS="*"
RESTRICT="mirror"
SRC_URI="http://www.funtoo.org/distfiles/binutils-2.20.1.tar.bz2
	http://www.funtoo.org/distfiles/binutils-2.20.1-patches-${PATCHVER}.tar.bz2"

