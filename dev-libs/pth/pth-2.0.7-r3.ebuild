# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit eutils fixheadtails libtool flag-o-matic

DESCRIPTION="GNU Portable Threads"
HOMEPAGE="http://www.gnu.org/software/pth/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="*"
IUSE="debug static-libs"

DEPEND=""
RDEPEND="${DEPEND}"

DOCS="ANNOUNCE AUTHORS ChangeLog NEWS README THANKS USERS"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.0.5-parallelfix.patch
	epatch "${FILESDIR}"/${PN}-2.0.6-ldflags.patch
	epatch "${FILESDIR}"/${PN}-2.0.6-sigstack.patch
	epatch "${FILESDIR}"/${PN}-2.0.7-parallel-install.patch
	epatch "${FILESDIR}"/${PN}-2.0.7-ia64.patch
	epatch "${FILESDIR}"/${PN}-2.0.7-kernel-3.patch

	ht_fix_file aclocal.m4 configure

	elibtoolize
}

src_configure() {
	# bug 350815
	( use arm || use sh ) && append-flags -U_FORTIFY_SOURCE

	local conf
	use debug && conf="${conf} --enable-debug"	# have a bug --disable-debug and shared
	# FL-1697: workaround for hanging configure check: 
	export ac_cv_stacksetup_sigaltstack='ok:(skaddr),(sksize)'
	econf \
		${conf} \
		$(use_enable static-libs static)
}

src_install() {
	default
	find "${ED}" -name '*.la' -exec rm -f {} +
}
