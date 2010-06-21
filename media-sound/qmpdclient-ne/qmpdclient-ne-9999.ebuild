# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2
inherit git eutils multilib qt4 toolchain-funcs

DESCRIPTION="An easy-to-use Qt4 client for MPD"
HOMEPAGE="http://github.com/Voker57/qmpdclient-ne/tree/master"
EGIT_REPO_URI="git://github.com/Voker57/qmpdclient-ne.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~hppa ppc ~sparc x86"
IUSE=""

RDEPEND="x11-libs/qt-gui:4
	x11-libs/qt-dbus:4"

src_prepare() {
	# Fix the install path
	sed -i -e "s:PREFIX = /usr/local:PREFIX = /usr:" qmpdclient.pro \
		|| die "sed failed"
}

src_compile() {
	eqmake4 qmpdclient.pro || die "qmake failed"
	emake || die "make failed"
}

src_install() {
	dodoc README AUTHORS THANKSTO Changelog
	for res in 16 22 32 64 128 ; do
		insinto /usr/share/icons/hicolor/${res}x${res}/apps/
		newins icons/qmpdclient${res}.png ${PN}.png
	done

	dobin qmpdclient || die "dobin failed"
	make_desktop_entry qmpdclient "QMPDClient" ${PN} "Qt;AudioVideo;Audio;"
}
