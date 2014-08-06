# Distributed under the terms of the GNU General Public License v2

EAPI="5"
inherit autotools eutils

DESCRIPTION="A system-independent library for user-level network packet capture"
HOMEPAGE="http://www.tcpdump.org/"
SRC_URI="http://www.tcpdump.org/release/${P}.tar.gz
	http://www.jp.tcpdump.org/release/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="bluetooth dbus ipv6 netlink static-libs canusb"

RDEPEND="
	bluetooth? ( net-wireless/bluez:= )
	dbus? ( sys-apps/dbus )
	netlink? ( dev-libs/libnl )
	canusb? ( virtual/libusb )
"
DEPEND="${RDEPEND}
	sys-devel/flex
	virtual/pkgconfig
	virtual/yacc
"

DOCS=( CREDITS CHANGES VERSION TODO README{,.dag,.linux,.macosx,.septel} )

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.2.0-cross-linux.patch

	# Prefix' Solaris uses GNU ld
	sed -e 's/freebsd\*/freebsd*|solaris*/' \
		-e 's/sparc64\*/sparc64*|sparcv9*/'  \
		-i aclocal.m4 || die
	# Prefix' Darwin systems are single arch, hijack Darwin7 case which
	# assumes this setup
	sed -e 's/darwin\[0-7\]\./darwin*/' \
		-i configure.in || die

	eautoreconf
}

src_configure() {
	econf \
		$(use_enable bluetooth) \
		$(use_enable ipv6) \
		$(use_enable canusb) \
		$(use_enable dbus) \
		$(use_with netlink libnl)
}

src_compile() {
	emake all shared
}

src_install() {
	default

	# remove static libraries (--disable-static does not work)
	if ! use static-libs; then
		find "${ED}" -name '*.a' -exec rm {} + || die
	fi
	prune_libtool_files

	# We need this to build pppd on G/FBSD systems
	if [[ "${USERLAND}" == "BSD" ]]; then
		insinto /usr/include
		doins pcap-int.h
	fi
}
