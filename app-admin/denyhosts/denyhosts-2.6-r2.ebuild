# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/denyhosts/denyhosts-2.6-r2.ebuild,v 1.1 2010/05/04 02:53:50 darkside Exp $

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
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ppc ~sparc ~x86"
IUSE=""

DEPEND=""
RDEPEND=""

RESTRICT_PYTHON_ABIS="3.*"
PYTHON_MODNAME="${MY_PN}"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	# changes default file installations
	epatch "${FILESDIR}"/${P}-gentoo.patch
	epatch "${FILESDIR}"/${P}-log-injection-regex.patch
	sed -i -e 's:DENY_THRESHOLD_VALID = 10:DENY_THRESHOLD_VALID = 5:' \
		denyhosts.cfg-dist || die "sed failed"
}

src_install() {
	DOCS="CHANGELOG.txt README.txt PKG-INFO"
	distutils_src_install

	insinto /etc
	insopts -m0640
	newins denyhosts.cfg-dist denyhosts.conf || die

	dodir /etc/logrotate.d
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/${PN}.logrotate ${PN} || die

	newinitd "${FILESDIR}"/denyhosts.init denyhosts || die

	# build system installs docs that we installed above
	rm -f "${D}"/usr/share/denyhosts/*.txt

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
