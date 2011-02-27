EAPI=2
inherit eutils
DESCRIPTION="The eXtensible Open Router Platform"
HOMEPAGE="http://www.xorp.org/"
SRC_URI="http://www.xorp.org/releases/${PV}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE="static debug ipv6 snmp"

DEPEND=">=dev-lang/python-2.0
	dev-libs/openssl
	sys-libs/ncurses
	snmp? ( net-analyzer/net-snmp )"
RDEPEND="${DEPEND}
	net-analyzer/traceroute"

pkg_setup() {
	enewgroup xorp
}

src_compile() {
	econf \
		$(use_enable static) \
		$(use_enable debug) \
		$(use_enable ipv6) \
		$(use_with snmp) \
		--prefix="/usr/lib/xorp" \
		--with-oslr \
		--with-pic \
		|| die "econf failed"

	# -Werror prevents building snmp agent...
	find "${S}" -name Makefile -exec sed -i -e '/^C.*FLAGS/s/-Werror//g' '{}' \;

	emake || die "emake failed"
}

src_test() {
	emake check || die "emake check failed"
}

src_prepare() {
	# applying patches from debian's xorp_1.6-3:
	cd ${S}
	for pat in $(cat ${FILESDIR}/patches/series | grep -v '^#' | sed -e 's/#.*//')
	do
		cat $FILESDIR/patches/$pat* | patch -p1 || die
	done
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	insinto /etc/xorp
	newins rtrmgr/config.boot.sample config.boot.dist

	newconfd "${FILESDIR}/xorp-confd" xorp
	newinitd "${FILESDIR}/xorp-initd" xorp

	dodoc BUGS ERRATA README RELEASE_NOTES TODO VERSION
}

pkg_postinst() {
	elog "Only users who belong to the xorp group"
	elog "can run xorpsh in configurational mode."
	elog "You must create /etc/xorp/config.boot,"
	elog "you can use the sample /etc/xorp/config.boot.dist"
}
