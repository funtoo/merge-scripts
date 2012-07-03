# Copyright 1999-2011 Gentoo Foundation; Copyright 2011 Funtoo Technologies
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit autotools multilib eutils libtool prefix

DESCRIPTION="A Client that groks URLs"
HOMEPAGE="http://curl.haxx.se/"
SRC_URI="http://curl.haxx.se/download/${P}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="*"
IUSE="ares idn ipv6 kerberos ldap ssh ssl static-libs test threads"
IUSE="${IUSE} curl_ssl_axtls curl_ssl_cyassl curl_ssl_gnutls curl_ssl_nss +curl_ssl_openssl curl_ssl_polarssl"

RDEPEND="ldap? ( net-nds/openldap )
	ssl? (
		curl_ssl_axtls? ( net-libs/axTLS app-misc/ca-certificates )
		curl_ssl_gnutls? (
			|| (
				( >=net-libs/gnutls-3[static-libs?] dev-libs/nettle )
				( =net-libs/gnutls-2.12*[nettle,static-libs?] dev-libs/nettle )
				( =net-libs/gnutls-2.12*[-nettle,static-libs?] dev-libs/libgcrypt[static-libs?] )
				( <net-libs/gnutls-2.12 dev-libs/libgcrypt[static-libs?] )
			)
			app-misc/ca-certificates
		)
		curl_ssl_openssl? ( dev-libs/openssl[static-libs?] )
		curl_ssl_nss? ( dev-libs/nss app-misc/ca-certificates )
		curl_ssl_polarssl? ( net-libs/polarssl app-misc/ca-certificates )
	)
	idn? ( net-dns/libidn[static-libs?] )
	ares? ( net-dns/c-ares )
	kerberos? ( virtual/krb5 )
	ssh? ( net-libs/libssh2[static-libs?] )
	sys-libs/zlib"

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

# ares must be disabled for threads
# only one ssl provider can be enabled
REQUIRED_USE="threads? ( !ares )
	ssl? (
		^^ (
			curl_ssl_axtls
			curl_ssl_cyassl
			curl_ssl_gnutls
			curl_ssl_openssl
			curl_ssl_nss
			curl_ssl_polarssl
		)
	)"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-7.19.7-test241.patch \
		"${FILESDIR}"/${PN}-7.18.2-prefix.patch \
		"${FILESDIR}"/${PN}-respect-cflags-3.patch \
		"${FILESDIR}"/${PN}-fix-gnutls-nettle.patch
	sed -i '/LD_LIBRARY_PATH=/d' configure.ac || die #382241
	eprefixify curl-config.in
	eautoreconf
}

src_configure() {
	einfo "\033[1;32m**************************************************\033[00m"

	# We make use of the fact that later flags override earlier ones
	# So start with all ssl providers off until proven otherwise
	local myconf=()
	myconf+=( --without-axtls --without-cyassl --without-gnutls --without-nss --without-polarssl --without-ssl )
	myconf+=( --with-ca-bundle="${EPREFIX}"/etc/ssl/certs/ca-certificates.crt )
	if use ssl ; then
		if use curl_ssl_axtls; then
			einfo "SSL provided by axTLS"
			einfo "NOTE: axTLS is meant for embedded systems and"
			einfo "may not be the best choice as an ssl provider"
			myconf+=( --with-axtls )
		fi
		if use curl_ssl_cyassl; then
			einfo "SSL provided by cyassl"
			einfo "NOTE: cyassl is meant for embedded systems and"
			einfo "may not be the best choice as an ssl provider"
			myconf+=( --with-cyassl )
		fi
		if use curl_ssl_gnutls; then
			einfo "SSL provided by gnutls"
			if has_version ">=net-libs/gnutls-3" || has_version "=net-libs/gnutls-2.12*[nettle]"; then
				einfo "gnutls compiled with dev-libs/nettle"
				myconf+=( --with-gnutls --with-nettle )
			else
				einfo "gnutls compiled with dev-libs/libgcrypt"
				myconf+=( --with-gnutls --without-nettle )
			fi
		fi
		if use curl_ssl_nss; then
			einfo "SSL provided by nss"
			myconf+=( --with-nss )
		fi
		if use curl_ssl_polarssl; then
			einfo "SSL provided by polarssl"
			einfo "NOTE: polarssl is meant for embedded systems and"
			einfo "may not be the best choice as an ssl provider"
			myconf+=( --with-polarssl )
		fi
		if use curl_ssl_openssl; then
			einfo "SSL provided by openssl"
			myconf+=( --with-ssl --without-ca-bundle --with-ca-path="${EPREFIX}"/etc/ssl/certs )
		fi
	else
		einfo "SSL disabled"
	fi
	einfo "\033[1;32m**************************************************\033[00m"

	# These configuration options are organized alphabetically
	# within each category.  This should make it easier if we
	# ever decide to make any of them contingent on USE flags:
	# 1) protocols first.  To see them all do
	# 'grep SUPPORT_PROTOCOLS configure.ac'
	# 2) --enable/disable options second.
	# 'grep -- --enable configure | grep Check | awk '{ print $4 }' | sort
	# 3) --with/without options third.
	# grep -- --with configure | grep Check | awk '{ print $4 }' | sort
	econf \
		--enable-dict \
		--enable-file \
		--enable-ftp \
		--enable-gopher \
		--enable-http \
		--enable-imap \
		$(use_enable ldap) \
		$(use_enable ldap ldaps) \
		--enable-pop3 \
		--without-librtmp \
		--enable-rtsp \
		$(use_with ssh libssh2) \
		--enable-smtp \
		--enable-telnet \
		--enable-tftp \
		$(use_enable ares) \
		--enable-cookies \
		--enable-hidden-symbols \
		$(use_enable ipv6) \
		--enable-largefile \
		--enable-manual \
		--enable-nonblocking \
		--enable-proxy \
		--disable-soname-bump \
		--disable-sspi \
		$(use_enable static-libs static) \
		$(use_enable threads threaded-resolver) \
		--disable-versioned-symbols \
		$(use_with idn libidn) \
		$(use_with kerberos gssapi "${EPREFIX}"/usr) \
		--without-krb4 \
		--without-spnego \
		--with-zlib \
		"${myconf[@]}"
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
