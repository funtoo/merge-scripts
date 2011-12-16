# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/metalog/metalog-2.ebuild,v 1.1 2011/09/23 03:15:23 vapier Exp $

EAPI="3"

inherit eutils

DESCRIPTION="A highly configurable replacement for syslogd/klogd"
HOMEPAGE="http://metalog.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="unicode"

RDEPEND=">=dev-libs/libpcre-3.4"
DEPEND="${RDEPEND}
	app-arch/xz-utils"

src_configure() {
	econf $(use_with unicode)
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	dodoc AUTHORS ChangeLog README NEWS metalog.conf

	# Replace stock metalog.conf with new one.
	rm -f "${D}/etc/metalog.conf"
	install "${FILESDIR}/metalog.conf" "${D}/etc/metalog.conf" -m 0600 -o root -g root

	into /
	dosbin "${FILESDIR}"/consolelog.sh || die
	dosbin "${FILESDIR}/metalog-postrotate-compress.sh" || die

	newinitd "${FILESDIR}"/metalog.initd metalog
	newconfd "${FILESDIR}"/metalog.confd metalog
}

pkg_preinst() {
	if [[ -d "${ROOT}"/etc/metalog ]] && [[ ! -e "${ROOT}"/etc/metalog.conf ]] ; then
		mv -f "${ROOT}"/etc/metalog/metalog.conf "${ROOT}"/etc/metalog.conf
		rmdir "${ROOT}"/etc/metalog
		export MOVED_METALOG_CONF=true
	else
		export MOVED_METALOG_CONF=false
	fi
}

pkg_postinst() {
	if ${MOVED_METALOG_CONF} ; then
		ewarn "The default metalog.conf file has been moved"
		ewarn "from /etc/metalog/metalog.conf to just"
		ewarn "/etc/metalog.conf.  If you had a standard"
		ewarn "setup, the file has been moved for you."
	fi
}
