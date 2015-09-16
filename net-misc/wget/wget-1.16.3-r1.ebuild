# Distributed under the terms of the GNU General Public License v2

EAPI="4"
PYTHON_COMPAT=( python{3_3,3_4} )
WANT_AUTOMAKE="1.4"

inherit flag-o-matic python-any-r1 toolchain-funcs autotools

DESCRIPTION="Network utility to retrieve files from the WWW"
HOMEPAGE="https://www.gnu.org/software/wget/"
SRC_URI="mirror://gnu/wget/${P}.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="*"
IUSE="debug gnutls idn ipv6 nls ntlm pcre +ssl static test uuid zlib"

LIB_DEPEND="idn? ( net-dns/libidn[static-libs(+)] )
	pcre? ( dev-libs/libpcre[static-libs(+)] )
	ssl? (
		gnutls? ( net-libs/gnutls[static-libs(+)] )
		!gnutls? ( dev-libs/openssl:0[static-libs(+)] )
	)
	uuid? ( sys-apps/util-linux[static-libs(+)] )
	zlib? ( sys-libs/zlib[static-libs(+)] )"
RDEPEND="!static? ( ${LIB_DEPEND//\[static-libs(+)]} )"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	virtual/pkgconfig
	static? ( ${LIB_DEPEND} )
	test? (
		${PYTHON_DEPS}
		dev-lang/perl
		dev-perl/HTTP-Daemon
		dev-perl/HTTP-Message
		dev-perl/IO-Socket-SSL
	)
	nls? ( sys-devel/gettext )"

REQUIRED_USE="ntlm? ( !gnutls ssl ) gnutls? ( ssl )"

DOCS=( AUTHORS MAILING-LIST NEWS README doc/sample.wgetrc )

pkg_setup() {
	use test && python-any-r1_pkg_setup
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-ftp-pasv-ip.patch #560418
}

src_configure() {
	# fix compilation on Solaris, we need filio.h for FIONBIO as used in
	# the included gnutls -- force ioctl.h to include this header
	[[ ${CHOST} == *-solaris* ]] && append-cppflags -DBSD_COMP=1

	if use static ; then
		append-ldflags -static
		tc-export PKG_CONFIG
		PKG_CONFIG+=" --static"
	fi
	econf \
		--disable-assert \
		--disable-rpath \
		$(use_with ssl ssl $(usex gnutls gnutls openssl)) \
		$(use_enable ssl opie) \
		$(use_enable ssl digest) \
		$(use_enable idn iri) \
		$(use_enable ipv6) \
		$(use_enable nls) \
		$(use_enable ntlm) \
		$(use_enable pcre) \
		$(use_enable debug) \
		$(use_with uuid libuuid) \
		$(use_with zlib)
}

src_test() {
	emake check
}

src_install() {
	default

	sed -i \
		-e "s:/usr/local/etc:${EPREFIX}/etc:g" \
		"${ED}"/etc/wgetrc \
		"${ED}"/usr/share/man/man1/wget.1 \
		"${ED}"/usr/share/info/wget.info
}
