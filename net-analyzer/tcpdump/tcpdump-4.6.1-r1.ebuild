# Distributed under the terms of the GNU General Public License v2

EAPI="5"

AUTOTOOLS_AUTO_DEPEND="no" # Only cross-compiling
inherit autotools eutils flag-o-matic toolchain-funcs user

DESCRIPTION="A Tool for network monitoring and data acquisition"
HOMEPAGE="http://www.tcpdump.org/"
SRC_URI="http://www.tcpdump.org/release/${P}.tar.gz
		http://www.jp.tcpdump.org/release/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE="+drop-root smi ssl ipv6 -samba suid test"

RDEPEND="
	drop-root? ( sys-libs/libcap-ng )
	net-libs/libpcap
	smi? ( net-libs/libsmi )
	ssl? ( >=dev-libs/openssl-0.9.6m )
"
DEPEND="
	${RDEPEND}
	drop-root? ( virtual/pkgconfig )
	test? (
		|| ( app-arch/sharutils sys-freebsd/freebsd-ubin )
		dev-lang/perl
	)
"

pkg_setup() {
	if use samba ; then
		ewarn
		ewarn "CAUTION !!! CAUTION !!! CAUTION"
		ewarn
		ewarn "You're about to compile tcpdump with samba printing support"
		ewarn "Upstream tags it with:"
		ewarn "WARNING: The SMB printer may have exploitable buffer overflows!!!"
		ewarn "So think twice whether this is fine with you"
		ewarn
		ewarn "CAUTION !!! CAUTION !!! CAUTION"
		ewarn
	fi
	if use drop-root || use suid; then
		enewgroup tcpdump
		enewuser tcpdump -1 -1 -1 tcpdump
	fi
}

src_prepare() {
	sed -i aclocal.m4 -e 's|\"-O2\"|\"\"|g' || die
	eautoconf
}
src_configure() {
	# tcpdump needs some optimization. see bug #108391
	# but do not replace -Os
	filter-flags -O[0-9]
	has -O? ${CFLAGS} || append-cflags -O2

	filter-flags -finline-functions

	if use drop-root; then
		append-cppflags -DHAVE_CAP_NG_H
		export LIBS=$( $(tc-getPKG_CONFIG) --libs libcap-ng )
	fi

	econf \
		$(use_enable ipv6) \
		$(use_enable samba smb) \
		$(use_with drop-root chroot '') \
		$(use_with smi) \
		$(use_with ssl crypto "${EPREFIX}/usr") \
		$(usex drop-root "--with-user=tcpdump" "")
}

src_test() {
	if [[ ${EUID} -ne 0 ]] || ! use drop-root; then
		sed -i -e '/^\(espudp1\|eapon1\)/d;' tests/TESTLIST || die
		emake check
	else
		ewarn "If you want to run the test suite, make sure you either"
		ewarn "set FEATURES=userpriv or set USE=-drop-root"
	fi
}

src_install() {
	dosbin tcpdump
	doman tcpdump.1
	dodoc *.awk
	dodoc CHANGES CREDITS README.md

	if use suid; then
		fowners root:tcpdump /usr/sbin/tcpdump
		fperms 4110 /usr/sbin/tcpdump
	fi
}

pkg_preinst() {
	if use drop-root || use suid; then
		enewgroup tcpdump
		enewuser tcpdump -1 -1 -1 tcpdump
	fi
}

pkg_postinst() {
	use suid && elog "To let normal users run tcpdump add them into tcpdump group."
}
