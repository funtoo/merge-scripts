# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/incron/incron-0.5.9.ebuild,v 1.1 2009/10/28 23:47:22 vapier Exp $

EAPI="2"

inherit eutils linux-info toolchain-funcs

DESCRIPTION="inotify based cron daemon"
HOMEPAGE="http://incron.aiken.cz/"
SRC_URI="http://inotify.aiken.cz/download/incron/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE=""

CONFIG_CHECK="~INOTIFY"
ERROR_INOTIFY="Recompile your kernel with inotify support - CONFIG_INOTIFY"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-0.5.8-gentoo.patch \
		"${FILESDIR}"/${PN}-0.5.8-gcc44.patch
}

src_compile() {
	emake CXX=$(tc-getCXX) CXXFLAGS="${CXXFLAGS}" || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc CHANGELOG README TODO
}
