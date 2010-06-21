# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit toolchain-funcs

DESCRIPTION="A collection of elementary building blocks for implementing compiler frontends in c++."
HOMEPAGE="http://kolpackov.net/projects/libfrontend-elements/"
SRC_URI="ftp://kolpackov.net/pub/projects/${PN}/${PV%.?}/${P}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="examples"

RDEPEND=">=dev-cpp/libcult-1.4.2"
DEPEND="${RDEPEND}
	dev-util/build"

src_compile() {
	mkdir -p build/{c,cxx/gnu,import/libcult}

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

	emake || die "emake failed"
}

src_install() {
	dolib.so frontend-elements/libfrontend-elements.so

	find frontend-elements -iname "*.cxx" \
		-o -iname "makefile" \
		-o -iname "*.o" -o -iname "*.d" \
		-o -iname "*.m4" -o -iname "*.l" \
		-o -iname "*.cpp-options" -o -iname "*.so" | xargs rm -f
	rm -rf frontend-elements/arch

	insinto /usr/include
	doins -r frontend-elements

	dodoc NEWS README
	dohtml -A xhtml -r documentation/*

	if use examples ; then
		insinto /usr/share/doc/${PF}
		doins -r examples
	fi
}
