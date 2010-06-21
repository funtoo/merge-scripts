# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/syslog-ng/syslog-ng-3.0.6.ebuild,v 1.6 2010/05/30 17:45:02 armin76 Exp $

EAPI=2
inherit fixheadtails eutils

MY_PV=${PV/_/}
DESCRIPTION="syslog replacement with advanced filtering features"
HOMEPAGE="http://www.balabit.com/products/syslog_ng/"
SRC_URI="http://www.balabit.com/downloads/files/syslog-ng/sources/${PV}/source/syslog-ng_${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ~ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="caps hardened ipv6 pcre selinux spoof-source sql ssl static tcpd"
RESTRICT="test"

LIBS_DEPEND="
	spoof-source? ( net-libs/libnet )
	ssl? ( dev-libs/openssl )
	tcpd? ( >=sys-apps/tcp-wrappers-7.6 )
	>=dev-libs/eventlog-0.2
	>=dev-libs/glib-2.10.1:2
	caps? ( sys-libs/libcap )
	sql? ( >=dev-db/libdbi-0.8.3 )"
RDEPEND="
	!static? (
		pcre? ( dev-libs/libpcre )
		${LIBS_DEPEND}
	)"
DEPEND="${RDEPEND}
	${LIBS_DEPEND}
	dev-util/pkgconfig
	sys-devel/flex"
PROVIDE="virtual/logger"

src_prepare() {
	ht_fix_file configure
}

src_configure() {
	local myconf

	if use static ; then
		myconf="${myconf} --enable-static-linking"
		if use pcre ; then
			ewarn "USE=pcre is incompatible with static linking"
			myconf="${myconf} --disable-pcre"
		fi
	else
			myconf="${myconf} --enable-dynamic-linking"
	fi
	econf \
		--disable-dependency-tracking \
		--sysconfdir=/etc/syslog-ng \
		--with-pidfile-dir=/var/run \
		$(use_enable caps linux-caps) \
		$(use_enable ipv6) \
		$(use_enable pcre) \
		$(use_enable spoof-source) \
		$(use_enable sql) \
		$(use_enable ssl) \
		$(use_enable tcpd tcp-wrapper) \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	dodoc AUTHORS ChangeLog NEWS README \
		doc/examples/{syslog-ng.conf.sample,syslog-ng.conf.solaris} \
		contrib/syslog-ng.conf* \
		contrib/syslog2ng "${FILESDIR}/syslog-ng.conf."*

	# Install default configuration
	insinto /etc/syslog-ng
	if use hardened || use selinux ; then
		newins "${FILESDIR}/syslog-ng.conf.gentoo.hardened.${PV%%.*}" syslog-ng.conf
	elif use userland_BSD ; then
		newins "${FILESDIR}/syslog-ng.conf.gentoo.fbsd.${PV%%.*}" syslog-ng.conf
	else
		newins "${FILESDIR}/syslog-ng.conf.gentoo.${PV%%.*}" syslog-ng.conf
	fi

	insinto /etc/logrotate.d
	# Install snippet for logrotate, which may or may not be installed
	if use hardened || use selinux ; then
		newins "${FILESDIR}/syslog-ng.logrotate.hardened" syslog-ng
	else
		newins "${FILESDIR}/syslog-ng.logrotate" syslog-ng
	fi

	newinitd "${FILESDIR}/syslog-ng.rc6.${PV%%.*}" syslog-ng
	newconfd "${FILESDIR}/syslog-ng.confd" syslog-ng
}

pkg_postinst() {
	echo
	elog "It is highly recommended that app-admin/logrotate be emerged to"
	elog "manage the log files.  ${PN} installs a file in /etc/logrotate.d"
	elog "for logrotate to use."
	echo
}
