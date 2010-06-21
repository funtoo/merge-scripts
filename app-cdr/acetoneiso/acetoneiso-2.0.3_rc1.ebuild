# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2

inherit eutils qt4

MY_P="${PN}_${PV/_rc/RC}"

DESCRIPTION="Graphical tool to do a lot things with image files like extracting, mounting, encrypting."
HOMEPAGE="http://www.acetoneteam.org/"
# switch back to the sf.net mirror later, if the tarball is also vailable there
#SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"
SRC_URI="http://www.acetoneteam.org/download/${MY_P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc"

# remove the blocker after some time
DEPEND="x11-libs/qt-gui
	x11-libs/qt-webkit
	!app-cdr/acetoneiso2"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}/acetoneiso/"

src_prepare() {
	# Fix prestripping bug 221745
	epatch "${FILESDIR}/${PN}-nostrip.patch"

	# unrar is called unrar-nonfree there
	sed -i -e 's:unrar-nonfree:unrar:g' sources/compress.h locale/*.ts \
		|| die "sed failed"
}

src_configure() {
	eqmake4
}

src_install() {
	emake INSTALL_ROOT="${D}" install || die "emake install failed"

	dodoc ../{AUTHORS,CHANGELOG,FEATURES,README} || die "dodoc failed"

	if use doc; then
		dohtml -r manual/* || die "dohtml failed"
	fi
}

pkg_postinst() {
	elog
	elog "The following packages will give ${PN} extended functionality:"

	elog "Filemanager:"
	elog "\tkde-base/dolphin"
	elog "\tkde-base/konqueror"
	elog "\tgnome-base/nautilus"

	elog "Video player:"
	elog "\tmedia-video/mplayer"
	elog "\tmedia-video/smplayer"
	elog "\tmedia-video/kaffeine"
	elog "\tmedia-video/vlc"

	elog "Image mounting:"
	elog "\tsys-fs/fuse"
	elog "\tsys-fs/fuseiso"

	elog "Image encryption:"
	elog "\t>=app-crypt/gnupg-2"

	elog "Image compression:"
	elog "\tapp-arch/p7zip"
	elog "\tapp-arch/unrar"

	elog "Encoding:"
	elog "\tmedia-video/ffmpeg"
	elog "\tmedia-sound/lame"
	elog "\tmedia-video/mplayer (mencoder)"

	elog "Device info:"
	elog "\tsys-apps/hal"

	elog "CD/DVD burning, image creation etc.:"
	elog "\tapp-cdr/cdrkit"
	elog "\tapp-cdr/cdrdao"
	elog "\tmedia-sound/cdparanoia"

	elog "Additional tools which are not in the portage tree:"
	elog "\tgeteltorito - http://www.uni-koblenz.de/~krienke/ftp/noarch/geteltorito/"
	elog "\tciso - http://ciso.tenshu.fr/"

	elog
	elog "for further informations see README"
	elog
}
