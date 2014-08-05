# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils

MY_P="gc-${PV/_/}"

DESCRIPTION="The Boehm-Demers-Weiser conservative garbage collector"
HOMEPAGE="http://www.hboehm.info/gc/"
SRC_URI="http://www.hboehm.info/gc/gc_source/${MY_P}.tar.gz"

LICENSE="boehm-gc"
SLOT="0"
KEYWORDS="*"
IUSE="cxx static-libs +threads"

DEPEND=">=dev-libs/libatomic_ops-7.2
	virtual/pkgconfig"

S="${WORKDIR}/${MY_P/f}"

src_configure() {
	local config=(
		--with-libatomic-ops
		$(use_enable cxx cplusplus)
		$(use_enable static-libs static)
		$(use threads || echo --disable-threads)
	)
	econf "${config[@]}"
}

src_install() {
	default
	use static-libs || prune_libtool_files

	insinto /usr/include/gc
	doins include/{ec.h,javaxfc.h}
	insinto /usr/include/gc/private
	doins include/private/*.h

	rm -r "${ED}"/usr/share/gc || die
	dodoc README.QUICK doc/README{.environment,.linux,.macros} doc/barrett_diagram
	dohtml doc/*.html
	newman doc/gc.man GC_malloc.1
}
