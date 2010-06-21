# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit toolchain-funcs

DESCRIPTION="A collection of C++ libraries"
HOMEPAGE="http://kolpackov.net/projects/libcult/"
SRC_URI="ftp://kolpackov.net/pub/projects/${PN}/${PV%.?}/${P}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="examples"

DEPEND="dev-util/build"
RDEPEND=""

src_compile() {
	mkdir -p build/{c,cxx/gnu}

	cat >> build/c/configuration-lib-dynamic.make <<- EOF
c_lib_type   := shared
	EOF

	cat >> build/configuration-dynamic.make <<- EOF
cult_dr := y
cult_threads := y
cult_network := y
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

	emake || die "emake failed"
}

src_install() {
	dolib.so cult/libcult.so

	find cult -iname "*.cxx" \
		-o -iname "makefile" \
		-o -iname "*.o" -o -iname "*.d" \
		-o -iname "*.m4" -o -iname "*.l" \
		-o -iname "*.cpp-options" -o -iname "*.so" | xargs rm -f
	rm -rf cult/arch

	insinto /usr/include
	doins -r cult

	dodoc NEWS README
	dohtml -A xhtml -r documentation/*

	if use examples ; then
		# preserving symlinks in the examples
		cp -dpR examples "${D}/usr/share/doc/${PF}"
	fi
}
