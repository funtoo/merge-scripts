# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils libtool toolchain-funcs

DESCRIPTION="BitTorrent library written in C++ for *nix"
HOMEPAGE="http://libtorrent.rakshasa.no/"
SRC_URI="http://libtorrent.rakshasa.no/downloads/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="debug ipv6 ssl test"

RDEPEND="
	>=dev-libs/libsigc++-2.2.2:2
	ssl? ( dev-libs/openssl )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	test? ( dev-util/cppunit )"
src_prepare() {
	elibtoolize
}

src_configure() {
	# the configure check for posix_fallocate is wrong.
	# reported upstream as Ticket 2416.
	local myconf
	echo "int main(){return posix_fallocate();}" > "${T}"/posix_fallocate.c
	if $(tc-getCC) ${CFLAGS} ${LDFLAGS} "${T}"/posix_fallocate.c -o /dev/null 2>/dev/null ; then
		myconf="--with-posix-fallocate"
	else
		myconf="--without-posix-fallocate"
	fi

	# configure needs bash or script bombs out on some null shift, bug #291229
	CONFIG_SHELL=${BASH} econf \
		--disable-dependency-tracking \
		--disable-instrumentation \
		--enable-aligned \
		$(use_enable debug) \
		$(use_enable ipv6) \
		$(use_enable ssl openssl) \
		${myconf}
}
