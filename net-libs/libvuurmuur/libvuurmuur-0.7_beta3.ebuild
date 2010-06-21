# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
# Made by Tiger!P

MY_PKG_NAME="Vuurmuur"
DESCRIPTION="iptables frontend. Common library and plugins."
HOMEPAGE="http://www.vuurmuur.org"
SRC_URI="mirror://sourceforge/vuurmuur/${MY_PKG_NAME}-${PV/_/}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~ppc"
IUSE=""

DEPEND=""
RDEPEND="net-firewall/iptables"

src_unpack() {
	unpack ${A} || die "Unpacking of ${A} did not succeed"
	cd ${MY_PKG_NAME}-${PV/_/} || die "Changing to the ${MY_PKG_NAME}-${PV/_/} directory failed"
	#einfo "pwd: ${PWD}"
	# Because we need to unpack something from the just unpacked file, we do it
	# like a shell command
	einfo "Unpacking ${P/_/}.tar.gz"
	gzip -cd ${P/_/}.tar.gz | tar xf - || die "Unpacking of ${P/_/}.tar.gz failed"
	#unpack ${P/_/}.tar.gz || die "Unpacking of ${P/_/}.tar.gz failed"
	#einfo "pwd: ${PWD}"
}

src_compile() {
	#einfo "pwd: ${PWD}"
	cd ${WORKDIR}/${MY_PKG_NAME}-${PV/_/}/${P/_/} || die
	libtoolize -f
	aclocal
	autoheader
	automake
	autoconf
	#./configure --prefix=/usr --sysconfdir=/etc
	econf --with-plugindir=/usr/lib/vuurmuur \
	--with-shareddir=/usr/share/vuurmuur || die "The configure script failed"
	emake || die "Making did not succeed"
}

src_install() {
	#einfo "pwd: ${PWD}"
	cd ${WORKDIR}/${MY_PKG_NAME}-${PV/_/}/${P/_/} || die "Could not change dirs"
	einstall
	insinto /etc/vuurmuur/plugins
	doins plugins/textdir/textdir.conf
}

