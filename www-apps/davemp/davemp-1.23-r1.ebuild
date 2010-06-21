# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit eutils multilib

DESCRIPTION="lightweight low-dependency web interface to mpd"
HOMEPAGE="http://ion0.com/davemp/"
SRC_URI="http://ion0.com/davemp/downloads/files/${P}.tar.gz"

LICENSE="CCPL-Attribution-NonCommercial-ShareAlike-2.5"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"

DEPEND="dev-perl/JSON-XS
	dev-perl/HTTP-Server-Simple
	dev-perl/Class-Accessor
	media-sound/mpd"

RDEPEND="${DEPEND}"

src_unpack() {
	unpack ${A}
	cd "${WORKDIR}/${P}"
	sed -i 's_themeroot = ./themes_themeroot=/usr/share/davemp/themes_' "davemp.conf"
	sed -i "s_use lib './lib'_use lib '/usr/lib/davemp/'_" "davempd.pl"
}

src_install() {
	doinitd "${FILESDIR}"/davemp
	insinto /usr/share/${PN}
	doins -r themes
	insinto /usr/$(get_libdir)/${PN}
	doins -r lib/*
	insinto /etc
	doins davemp.conf
	dobin davempd.pl
	dodoc README Changelog
}
