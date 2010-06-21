# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

DESCRIPTION="automatic audio file renaming"
HOMEPAGE="http://ft.bewatermyfriend.org/comp/arename.html"
SRC_URI="http://ft.bewatermyfriend.org/comp/${PN}/${PN}-v${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="zsh-completion"

DEPEND=""
RDEPEND="dev-perl/Readonly
	dev-perl/MP3-Tag
	dev-perl/ogg-vorbis-header
	dev-perl/Audio-FLAC-Header"

S=${WORKDIR}/${PN}-v${PV}
RESTRICT="test"

src_compile() {
	# make would only display a usage statement
	true
}

src_install() {
	emake install prefix="${D}/usr" libpath="lib/perl5/site_perl" || die "emake install failed"
	emake install-doc prefix="${D}/usr" || die "emake install doc failed"

	if use zsh-completion; then
		insinto /usr/share/zsh/site-functions
		doins _arename
	fi
}
