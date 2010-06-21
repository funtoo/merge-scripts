# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/metro/metro-1.4.1.ebuild,v 1.1 2009/07/22 09:48:11 hollow Exp $

EAPI="2"

DESCRIPTION="Sample network configuration scripts for Funtoo Linux"
HOMEPAGE="http://www.funtoo.org/en/funtoo/networking"
SRC_URI="http://www.funtoo.org/archive/funtoo-netscripts/${P}.tar.bz2"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="amd64 x86"

DEPEND=""

src_install() {
	install -d ${D}/usr/share/doc/${P}
	cp -a ${S}/* ${D}/usr/share/doc/${P}
}
