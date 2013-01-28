# Distributed under the terms of the GNU General Public License v2

EAPI=4
inherit eutils toolchain-funcs python

DESCRIPTION="Central Regulatory Domain Agent for wireless networks."
HOMEPAGE="http://wireless.kernel.org/en/developers/Regulatory"
SRC_URI="http://linuxwireless.org/download/crda/${P}.tar.bz2"

LICENSE="ISC"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="dev-libs/openssl:0
	dev-libs/libnl:3
	net-wireless/wireless-regdb
	>=virtual/udev-171"
DEPEND="${RDEPEND} virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/crda-1.1.3-missing-include.patch
	#epatch "${FILESDIR}"/crda-1.1.3-nopython.patch
	sed -i \
		-e "s:\<pkg-config\>:$(tc-getPKG_CONFIG):" \
		Makefile || die
	# this eliminates a python dep.
	cp ${FILESDIR}/keys-ssl.c . || die
}

src_compile() {
	emake \
		UDEV_RULE_DIR="$($(tc-getPKG_CONFIG) --variable=udevdir udev)/rules.d" \
		REG_BIN=/usr/$(get_libdir)/crda/regulatory.bin \
		USE_OPENSSL=1 \
		CC="$(tc-getCC)" \
		all_noverify V=1
}

src_test() {
	emake USE_OPENSSL=1 CC="$(tc-getCC)" verify
}

src_install() {
	emake \
		UDEV_RULE_DIR="$($(tc-getPKG_CONFIG) --variable=udevdir udev)/rules.d" \
		REG_BIN=/usr/$(get_libdir)/crda/regulatory.bin \
		USE_OPENSSL=1 \
		DESTDIR="${D}" \
		install

	keepdir /etc/wireless-regdb/pubkeys
}
