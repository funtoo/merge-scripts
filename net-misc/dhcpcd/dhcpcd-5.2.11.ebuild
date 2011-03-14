# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/dhcpcd/dhcpcd-5.2.10-r1.ebuild,v 1.1 2011/01/04 23:13:45 williamh Exp $

EAPI=1

inherit eutils

DESCRIPTION="A fully featured, yet light weight RFC2131 compliant DHCP client"
HOMEPAGE="http://roy.marples.name/projects/dhcpcd/"
SRC_URI="http://roy.marples.name/downloads/${PN}/${P}.tar.bz2"
LICENSE="BSD-2"

KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc x86 ~sparc-fbsd ~x86-fbsd"

SLOT="0"
IUSE="+zeroconf elibc_glibc"

DEPEND=""
RDEPEND=""
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

src_compile() {
	local hooks="--with-hook=ntp.conf"
	use elibc_glibc && hooks="${hooks} --with-hook=yp.conf"
	econf --prefix= --libexecdir=/$(get_libdir)/dhcpcd --dbdir=/var/lib/dhcpcd \
		--localstatedir=/var ${hooks}
	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc README || die
	newinitd "${FILESDIR}"/${PN}.initd-r3 ${PN}
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

	elog "Please note that this version of dhcpcd's initscript does not provide"
	elog "'net'. This means that if you would like dhcpcd to start at boot, you"
	elog "need to add it to the proper runlevel by typing something like:"
	elog
	elog "rc-update add dhcpcd default"
}
