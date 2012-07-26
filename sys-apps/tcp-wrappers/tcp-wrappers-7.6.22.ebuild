# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit eutils toolchain-funcs versionator flag-o-matic

MY_PV=$(get_version_component_range 1-2)
DEB_PV=$(get_version_component_range 3)
MY_P="${PN//-/_}_${MY_PV}"
DESCRIPTION="TCP Wrappers"
HOMEPAGE="ftp://ftp.porcupine.org/pub/security/index.html"
SRC_URI="ftp://ftp.porcupine.org/pub/security/${MY_P}.tar.gz
	mirror://debian/pool/main/t/${PN}/${PN}_${MY_PV}.q-${DEB_PV}.debian.tar.gz"

LICENSE="tcp_wrappers_license"
SLOT="0"
KEYWORDS="~*"
IUSE="ipv6 netgroups static-libs"

S=${WORKDIR}/${MY_P}

src_prepare() {
	EPATCH_OPTS="-p1" \
	epatch $(sed -e 's:^:../debian/patches/:' ../debian/patches/series)
	epatch "${FILESDIR}"/${PN}-7.6-headers.patch
	epatch "${FILESDIR}"/${PN}-7.6-redhat-bug11881.patch
}

temake() {
	emake \
		REAL_DAEMON_DIR=/usr/sbin \
		TLI= VSYSLOG= PARANOID= BUGS= \
		AUTH="-DALWAYS_RFC931" \
		AUX_OBJ="weak_symbols.o" \
		DOT="-DAPPEND_DOT" \
		HOSTNAME="-DALWAYS_HOSTNAME" \
		NETGROUP=$(usex netgroups -DNETGROUPS "") \
		STYLE="-DPROCESS_OPTIONS" \
		LIBS=$(usex netgroups -lnsl "") \
		LIB=$(usex static-libs libwrap.a "") \
		AR="$(tc-getAR)" ARFLAGS=rc \
		CC="$(tc-getCC)" \
		RANLIB="$(tc-getRANLIB)" \
		COPTS="${CFLAGS} ${CPPFLAGS}" \
		LDFLAGS="${LDFLAGS}" \
		"$@" || die
}

src_configure() {
	tc-export AR CC RANLIB
	append-cppflags -DHAVE_WEAKSYMS -DHAVE_STRERROR -DSYS_ERRLIST_DEFINED
	use ipv6 && append-cppflags -DINET6=1 -Dss_family=__ss_family -Dss_len=__ss_len
	temake config-check
}

src_compile() {
	temake all
}

src_install() {
	dosbin tcpd tcpdchk tcpdmatch safe_finger try-from || die

	doman *.[358]
	dosym hosts_access.5 /usr/share/man/man5/hosts.allow.5
	dosym hosts_access.5 /usr/share/man/man5/hosts.deny.5

	insinto /etc
	newins "${FILESDIR}"/hosts.allow.example hosts.allow

	insinto /usr/include
	doins tcpd.h

	into /usr
	use static-libs && dolib.a libwrap.a
	dolib.so shared/libwrap.so*
	gen_usr_ldscript -a wrap

	dodoc BLURB CHANGES DISCLAIMER README*
}

pkg_preinst() {
	# don't clobber people with our default example config
	[[ -e ${ROOT}/etc/hosts.allow ]] && cp -pP "${ROOT}"/etc/hosts.allow "${D}"/etc/hosts.allow
}
