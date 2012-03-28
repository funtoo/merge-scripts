# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-dns/openresolv/openresolv-3.3.4.ebuild,v 1.7 2010/09/30 21:30:23 ranger Exp $

EAPI=2

DESCRIPTION="A framework for managing DNS information"
HOMEPAGE="http://roy.marples.name/projects/openresolv"
SRC_URI="http://roy.marples.name/downloads/${PN}/${P}.tar.bz2"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

DEPEND="!net-dns/resolvconf-gentoo
	!<net-dns/dnsmasq-2.40-r1"
RDEPEND=""

pkg_setup() {
	export PREFIX=
	export LIBEXECDIR="${PREFIX}/lib/resolvconf"
}

src_install() {
	emake DESTDIR="${D}" install || die
	exeinto /lib/resolvconf/
	doexe "${FILESDIR}/pdnsd" || die
}

pkg_postinst() {
	einfo "${PN}-3.0 has a new configuration file /etc/resolvconf.conf"
	einfo "instead of mini files in different directories."
	einfo "You should configure /etc/resolvconf.conf if you use a resolver"
	einfo "other than libc."
}

pkg_config() {
	if [ "${ROOT}" != "/" ]; then
		eerror "We cannot configure unless \$ROOT=/"
		return 1
	fi

	if [ -n "$(resolvconf -l)" ]; then
		einfo "${PN} already has DNS information"
	else
		ebegin "Copying /etc/resolv.conf to resolvconf -a dummy"
		resolvconf -a dummy </etc/resolv.conf
		eend $? || return $?
		einfo "The dummy interface will disappear when you next reboot"
	fi
}
