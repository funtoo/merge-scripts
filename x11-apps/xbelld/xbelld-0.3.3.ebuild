# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

DESCRIPTION="X daemon that performs an action every time the bell is rung"
HOMEPAGE="http://http://code.google.com/p/xbelld/"
SRC_URI="http://xbelld.googlecode.com/files/${P}.tbz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="alsa minimal"

RDEPEND="x11-libs/libX11
	alsa? ( media-libs/alsa-lib )"

DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_compile() {
	use alsa || export WITHOUT_ALSA=1
	use minimal && export CFLAGS="${CFLAGS} -DNO_WAVE"
	NO_DEBUG=1 emake || die
}

src_install() {
	dobin xbelld
	doman xbelld.1
	dodoc README ChangeLog
}
