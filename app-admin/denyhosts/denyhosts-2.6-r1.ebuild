# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/denyhosts/denyhosts-2.6-r1.ebuild,v 1.10 2009/12/25 21:59:20 arfrever Exp $

EAPI="2"
SUPPORT_PYTHON_ABIS="1"

inherit distutils eutils

MY_PN="DenyHosts"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="DenyHosts is a utility to help sys admins thwart ssh hackers"
HOMEPAGE="http://www.denyhosts.net"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ~ppc sparc x86"
IUSE=""

DEPEND=""
RDEPEND=""
RESTRICT_PYTHON_ABIS="3.*"

S="${WORKDIR}/${MY_P}"

PYTHON_MODNAME="${MY_PN}"

src_prepare() {
	# changes default file installations
	epatch "${FILESDIR}"/${P}-gentoo.patch
	epatch "${FILESDIR}"/${P}-log-injection-regex.patch
	sed -i -e 's:DENY_THRESHOLD_VALID = 10:DENY_THRESHOLD_VALID = 5:' \
		denyhosts.cfg-dist || die "sed failed"
}

src_install() {
	distutils_src_install

	insinto /etc
	insopts -m0640
	newins denyhosts.cfg-dist denyhosts.conf

	newinitd "${FILESDIR}"/denyhosts.init denyhosts

	dodoc CHANGELOG.txt README.txt

	keepdir /var/lib/denyhosts
}

pkg_postinst() {
	distutils_pkg_postinst

	if [[ ! -f "${ROOT}etc/hosts.deny" ]]; then
		touch "${ROOT}etc/hosts.deny"
	fi

	elog "You can configure DenyHosts to run as a daemon by running:"
	elog
	elog "rc-update add denyhosts default"
	elog
	elog "or as a cronjob, by adding the following to /etc/crontab"
	elog "# run DenyHosts every 10 minutes"
	elog "*/10  *  * * *	root	/usr/bin/denyhosts.py -c /etc/denyhosts.conf"
	elog
	elog "More information can be found at http://denyhosts.sourceforge.net/faq.html"
	elog
	ewarn "Modify /etc/denyhosts.conf to suit your environment system."
}
