# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
# Made by Tiger!P

MY_PKG_NAME="Vuurmuur"
DESCRIPTION="Iptables frontend. Ncurses GUI, for administration and monitoring."
HOMEPAGE="http://www.vuurmuur.org"
SRC_URI="mirror://sourceforge/vuurmuur/${MY_PKG_NAME}-${PV/_/}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ppc"
IUSE=""

DEPEND=""
RDEPEND="net-firewall/iptables
	=net-firewall/vuurmuur-${PV}
	>=sys-libs/ncurses-5"

src_unpack() {
	unpack ${A} || die "Unpacking of ${A} did not succeed"
	cd ${MY_PKG_NAME}-${PV/_/} || die "Changing to the ${MY_PKG_NAME}-${PV/_/} directory failed"
	#einfo "pwd: ${PWD}"
	# Because we need to unpack something from the just unpacked file, we do it
	# like a shell command
	einfo "Unpacking ${PN/-/_}-${PV/_/}.tar.gz"
	gzip -cd ${PN/-/_}-${PV/_/}.tar.gz | tar xf - || die "Unpacking of ${PN/-/_}-${PV/_/}.tar.gz failed"
	#unpack ${PN/-/_}-${PV/_/}.tar.gz || die "Unpacking of ${PN/-/_}-${PV/_/}.tar.gz failed"
	#einfo "pwd: ${PWD}"
}

src_compile() {
	#einfo "pwd: ${PWD}"
	cd ${WORKDIR}/${MY_PKG_NAME}-${PV/_/}/${PN/-/_}-${PV/_/} || die
	libtoolize -f
	aclocal
	autoheader
	automake
	autoconf
	econf --with-libvuurmuur-includes=/usr/include \
	--with-libvuurmuur-libraries=/usr/lib --with-localedir=/usr/share/locale \
	--with-widec=yes \
	|| die "The configure script failed"
	emake || die "Making did not succeed"
}

src_install() {
	#einfo "pwd: ${PWD}"
	cd ${WORKDIR}/${MY_PKG_NAME}-${PV/_/}/${PN/-/_}-${PV/_/} || die "Could not change dirs"
	einstall
}

