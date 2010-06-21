# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/elltube/elltube-0.3-r1.ebuild,v 1.6 2010/04/22 17:44:54 hwoarang Exp $

PYTHON_DEPEND="2"

EAPI="2"

inherit python eutils

DESCRIPTION="A YouTube Downloader and Converter"
HOMEPAGE="http://sourceforge.net/projects/elltube"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE=""

RDEPEND="dev-python/PyQt4[X]
	media-video/ffmpeg"

pkg_setup() {
	python_set_active_version 2
}

src_compile() {
	#just pass since make command does nasty stuff :)
	true
}

src_install() {
	emake DESTDIR="${D}" PREFIX="/usr" install || die "emake install failed"
	dodoc CHANGELOG || die "dodoc failed"
}
