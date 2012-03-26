# Copyright 1999-2011 Gentoo Foundation; Copyright 2011 Funtoo Technologies
# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit autotools multilib eutils libtool prefix

DESCRIPTION="A Client that groks URLs"
HOMEPAGE="http://curl.haxx.se/"
SRC_URI="http://curl.haxx.se/download/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~*"
IUSE="ares gnutls idn ipv6 kerberos ldap ssh nss ssl static-libs test threads"

RDEPEND="ldap? ( net-nds/openldap )
		gnutls? ( net-libs/gnutls dev-libs/libgcrypt app-misc/ca-certificates )
		nss? ( !gnutls? ( !ssl? ( dev-libs/nss app-misc/ca-certificates ) ) )
		ssl? ( !gnutls? ( dev-libs/openssl ) )
		idn? ( net-dns/libidn )
		ares? ( >=net-dns/c-ares-1.6 )
		kerberos? ( virtual/krb5 )
		ssh? ( >=net-libs/libssh2-0.16 )"

# rtmpdump ( media-video/rtmpdump )  / --with-librtmp
# fbopenssl (not in gentoo) --with-spnego
# krb4 http://web.mit.edu/kerberos/www/krb4-end-of-life.html

DEPEND="${RDEPEND}
	sys-apps/ed
	test? (
		sys-apps/diffutils
		dev-lang/perl
	)"
# used - but can do without in self test: net-misc/stunnel

# ares must be disabled for threads and both can be disabled
# one can use wether gnutls or nss if ssl is enabled
REQUIRED_USE="threads? ( !ares ) nss? ( !gnutls )"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-7.19.7-test241.patch \
		"${FILESDIR}"/${PN}-7.18.2-prefix.patch \
		"${FILESDIR}"/${PN}-respect-cflags-3.patch
	sed -i '/LD_LIBRARY_PATH=/d' configure.ac || die #382241
	eprefixify curl-config.in
	eautoreconf
}

src_configure() {
	local myconf

	myconf="$(use_enable ldap)
		$(use_enable ldap ldaps)
		$(use_with idn libidn)
		$(use_with kerberos gssapi "${EPREFIX}"/usr)
		$(use_with ssh libssh2)
		$(use_enable static-libs static)
		$(use_enable ipv6)
		$(use_enable threads threaded-resolver)
		$(use_enable ares)
		--enable-http
		--enable-ftp
		--enable-gopher
		--enable-file
		--enable-dict
		--enable-manual
		--enable-telnet
		--enable-smtp
		--enable-pop3
		--enable-imap
		--enable-rtsp
		--enable-nonblocking
		--enable-largefile
		--enable-maintainer-mode
		--disable-sspi
		--without-krb4
		--without-librtmp
		--without-spnego"

		if use gnutls; then
			myconf+=" --without-ssl --with-gnutls --without-nss"
			myconf+=" --with-ca-bundle=${EPREFIX}/etc/ssl/certs/ca-certificates.crt"
		elif use nss; then
			myconf+=" --without-ssl --without-gnutls --with-nss"
			myconf+=" --with-ca-bundle=${EPREFIX}/etc/ssl/certs/ca-certificates.crt"
		elif use ssl; then
			myconf+=" --without-gnutls --without-nss --with-ssl"
			myconf+=" --with-ca-bundle=${EPREFIX}/etc/ssl/certs/ca-certificates.crt"
		else
			myconf+=" --without-gnutls --without-nss --with-ssl"
			myconf+=" --without-ca-bundle --with-ca-path=${EPREFIX}/etc/ssl/certs"
		fi
	econf ${myconf}
}

src_compile() {

	default

	# curl seems to be in troubles when being cross-compiled in the amd64 world as a 32 bits binary (wrong
	# sizes are configured by configuration scripts thus making the package to break) unfortunately the
	# original Gentoo ebuild at revision 7.22.0 assumes this is was true everywhere and makes things badly
	# broken on other arches like sparc64

	if [ ${PROFILE_ARCH} != "sparc64" ] ; then
		ed - lib/curl_config.h < "${FILESDIR}"/config.h.ed || die
		ed - src/curl_config.h < "${FILESDIR}"/config.h.ed || die
		ed - include/curl/curlbuild.h < "${FILESDIR}"/curlbuild.h.ed || die
	fi
}

src_install() {
	default
	find "${ED}" -name '*.la' -exec rm -f {} +
	rm -rf "${ED}"/etc/

	# https://sourceforge.net/tracker/index.php?func=detail&aid=1705197&group_id=976&atid=350976
	insinto /usr/share/aclocal
	doins docs/libcurl/libcurl.m4

	dodoc CHANGES README
	dodoc docs/FEATURES docs/INTERNALS
	dodoc docs/MANUAL docs/FAQ docs/BUGS docs/CONTRIBUTE
}
