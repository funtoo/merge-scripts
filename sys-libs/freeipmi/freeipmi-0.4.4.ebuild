# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/freeipmi/freeipmi-0.4.4.ebuild,v 1.3 2009/10/13 13:52:12 ssuominen Exp $

inherit flag-o-matic

DESCRIPTION="FreeIPMI provides Remote-Console and System Management Software as per IPMI v1.5/2.0"
HOMEPAGE="http://www.gnu.org/software/freeipmi/"
SRC_URI="ftp://ftp.zresearch.com/pub/${PN}/${PV}/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
RDEPEND="dev-scheme/guile
	dev-libs/libgcrypt"
DEPEND="${RDEPEND}
	virtual/os-headers
	sys-apps/sed"

src_unpack() {
	unpack ${A}
	sed 's,auth_type_t,output_type_t,' -i.orig \
		"${S}"/ipmipower/src/ipmipower_output.c \
		|| die "Failed to fix ipmipower"
}

src_compile() {
	# this is to make things compile
	append-flags "-DHAVE_VPRINTF=1"

	econf --disable-init-scripts --enable-syslog --localstatedir=/var || die "econf failed"
	emake || die "emake failed"
}

src_install() {
	emake DESTDIR="${D}" docdir="/usr/share/doc/${PF}" install || die "emake install failed"
	# INSTALL contains usage instructions!
	dodoc AUTHORS ChangeLog* DISCLAIMER* NEWS README* TODO INSTALL*
	dodoc doc/*.txt
	# normal GPL2
	rm -f "${D}"/usr/share/doc/${PF}/COPYING
	# sysVinit scripts. need conversion to Gentoo.
	newdoc "${S}"/bmc-watchdog/freeipmi-bmc-watchdog.init redhat_bmc-watchdog.init
	newdoc "${S}"/ipmidetect/freeipmi-ipmidetectd.init redhat_ipmidetectd.init
}
