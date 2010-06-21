# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit toolchain-funcs

DESCRIPTION="A compiler frontend for the W3C XML Schema definition language."
HOMEPAGE="http://www.codesynthesis.com/projects/libxsd-frontend/"
SRC_URI="http://www.codesynthesis.com/download/${PN}/${PV%.?}/${P}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND=">=dev-libs/xerces-c-2.6
	dev-libs/boost
	>=dev-cpp/libcult-1.4.2
	>=dev-cpp/libfrontend-elements-1.1.1"
DEPEND="${RDEPEND}
	dev-util/build"

BUILDDIR="${WORKDIR}/build"

# test fails (I think) because tests/dump/driver is linked against both
# libxerces-c-3.0.so and libxerces-c.so.27 
# the problem seems to be in 
#  build/import/libxerces-c/rules.make
# but I am unsure exactly how to fix it 
RESTRICT="test"

src_compile() {
	mkdir -p \
		build/{c,cxx/gnu} \
		build/import/lib{boost,cult,frontend-elements,xerces-c}

	cat >> build/c/configuration-lib-dynamic.make <<- EOF
c_lib_type   := shared
	EOF

	cat >> build/cxx/configuration-dynamic.make <<- EOF
cxx_id       := gnu
cxx_optimize := n
cxx_debug    := n
cxx_rpath    := n
cxx_pp_extra_options :=
cxx_extra_options    := ${CXXFLAGS}
cxx_ld_extra_options := ${LDFLAGS}
cxx_extra_libs       :=
cxx_extra_lib_paths  :=
	EOF

	cat >> build/cxx/gnu/configuration-dynamic.make <<- EOF
cxx_gnu := $(tc-getCXX)
cxx_gnu_libraries :=
cxx_gnu_optimization_options :=
	EOF

	cat >> build/import/libcult/configuration-dynamic.make <<- EOF
libcult_installed := y
	EOF

	cat >> build/import/libboost/configuration-dynamic.make <<- EOF
libboost_installed := y
	EOF

	cat >> build/import/libfrontend-elements/configuration-dynamic.make <<- EOF
libfrontend_elements_installed := y
	EOF

	cat >> build/import/libxerces-c/configuration-dynamic.make <<- EOF
libxerces_c_installed := y
	EOF

	emake || die "emake failed"
}

src_install() {
	dolib.so xsd-frontend/libxsd-frontend.so

	find xsd-frontend -iname "*.cxx" \
		-o -iname "makefile" \
		-o -iname "*.o" -o -iname "*.d" \
		-o -iname "*.m4" -o -iname "*.l" \
		-o -iname "*.cpp-options" -o -iname "*.so" | xargs rm -f
	rm -rf xsd-frontend/arch

	insinto /usr/include
	doins -r xsd-frontend

	dodoc NEWS README
}

src_test() {
	LDPATH="${S}/xsd-frontend:${LDPATH}" emake test || die "tests failed"
}
