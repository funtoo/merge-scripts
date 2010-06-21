# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/dhcpcd/dhcpcd-5.0.6.ebuild,v 1.2 2009/07/31 17:01:30 ssuominen Exp $

EAPI=1

inherit toolchain-funcs eutils

MY_P="${P/_alpha/-alpha}"
MY_P="${MY_P/_beta/-beta}"
MY_P="${MY_P/_rc/-rc}"
S="${WORKDIR}/${MY_P}"

DESCRIPTION="A fully featured, yet light weight RFC2131 compliant DHCP client"
HOMEPAGE="http://roy.marples.name/projects/dhcpcd/"
SRC_URI="http://roy.marples.name/downloads/${PN}/${MY_P}.tar.bz2"
LICENSE="BSD-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"

SLOT="0"
IUSE="+zeroconf"

DEPEND=""
PROVIDE="virtual/dhcpc"

src_unpack() {
	unpack ${A}
	cd "${S}"

	if ! use zeroconf; then
		elog "Disabling zeroconf support"
		{
			echo
			echo "# dhcpcd ebuild requested no zeroconf"
			echo "noipv4ll"
		} >> dhcpcd.conf
	fi
}

pkg_setup() {
	MAKE_ARGS="DBDIR=/var/lib/dhcpcd LIBEXECDIR=/lib/dhcpcd"
}

src_compile() {
	[ -z "${MAKE_ARGS}" ] && die "MAKE_ARGS is empty"
	emake CC="$(tc-getCC)" ${MAKE_ARGS} || die
}

src_install() {
	local hooks="50-ntp.conf"
	use elibc_glibc && hooks="${hooks} 50-yp.conf"
	use compat && hooks="${hooks} 50-dhcpcd-compat"
	emake ${MAKE_ARGS} HOOKSCRIPTS="${hooks}" DESTDIR="${D}" install || die

	newinitd "${FILESDIR}"/${PN}.initd ${PN}
}

pkg_postinst() {
	# Upgrade the duid file to the new format if needed
	local old_duid="${ROOT}"/var/lib/dhcpcd/dhcpcd.duid
	local new_duid="${ROOT}"/etc/dhcpcd.duid
	if [ -e "${old_duid}" ] && ! grep -q '..:..:..:..:..:..' "${old_duid}"; then
		sed -i -e 's/\(..\)/\1:/g; s/:$//g' "${old_duid}"
	fi

	# Move the duid to /etc, a more sensible location
	if [ -e "${old_duid}" -a ! -e "${new_duid}" ]; then
		cp -p "${old_duid}" "${new_duid}"
	fi

	if use zeroconf; then
		elog "You have installed dhcpcd with zeroconf support."
		elog "This means that it will always obtain an IP address even if no"
		elog "DHCP server can be contacted, which will break any existing"
		elog "failover support you may have configured in your net configuration."
		elog "This behaviour can be controlled with the -L flag."
		elog "See the dhcpcd man page for more details."
	fi

	elog
	elog "Users transfering from 4.0 series should pay attention to removal"
	elog "of compat useflag. This changes behavior of dhcp in wide manner:"
	elog "dhcpcd no longer sends a default ClientID for ethernet interfaces."
	elog "This is so we can re-use the address the kernel DHCP client found."
	elog "To retain the old behaviour of sending a default ClientID based on the"
	elog "hardware address for interface, simply add the keyword clientid"
	elog "to dhcpcd.conf or use commandline parameter -I ''"
}
