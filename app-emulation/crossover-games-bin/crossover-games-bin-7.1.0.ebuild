# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

DESCRIPTION="simplified/streamlined version of wine geared towards games"
HOMEPAGE="http://www.codeweavers.com/products/cxgames/"
SRC_URI="install-crossover-games-demo-${PV}.sh"

LICENSE="CROSSOVER"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE="nas"
RESTRICT="fetch strip"

RDEPEND="sys-libs/glibc
	x11-libs/libXrandr
	x11-libs/libXi
	x11-libs/libXmu
	x11-libs/libXxf86dga
	x11-libs/libXxf86vm
	dev-util/desktop-file-utils
	nas? ( media-libs/nas )
	amd64? ( app-emulation/emul-linux-x86-xlibs )"

S=${WORKDIR}

pkg_nofetch() {
	einfo "Please visit ${HOMEPAGE}"
	einfo "and place ${A} in ${DISTDIR}"
}

src_unpack() {
	unpack_makeself
}

src_install() {
	dodir /opt/cxgames
	cp -r * "${D}"/opt/cxgames || die "cp failed"
	rm -r "${D}"/opt/cxgames/setup.{sh,data}
	insinto /opt/cxgames/etc
	doins share/crossover/data/cxgames.conf
	make_desktop_entry /opt/cxgames/bin/cxsetup "Crossover Games Setup" /opt/cxgames/share/icons/crossover.xpm 'Game;PackageManager'
}

pkg_postinst() {
	elog "Run /opt/cxgames/bin/cxsetup as normal user to create"
	elog "bottles and install Windows applications."
}
