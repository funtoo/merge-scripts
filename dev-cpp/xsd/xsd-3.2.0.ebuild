# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit toolchain-funcs eutils versionator

MY_P="${P/_beta/.b}"

DESCRIPTION="An open-source, cross-platform W3C XML Schema to C++ data binding compiler."
HOMEPAGE="http://www.codesynthesis.com/products/xsd/"
SRC_URI="http://www.codesynthesis.com/download/${PN}/$(get_version_component_range 1-2)/${MY_P}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="ace dbxml examples"

RDEPEND=">=dev-libs/xerces-c-2.6
	dev-libs/boost
	>=dev-cpp/libcult-1.4.2
	>=dev-cpp/libxsd-frontend-1.15.0
	>=dev-cpp/libbackend-elements-1.6.1
	ace? ( dev-libs/ace )
	dbxml? ( dev-libs/dbxml )"
DEPEND="${RDEPEND}
	dev-util/build"

S="${WORKDIR}/${MY_P}"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}/3.1.0-disable_examples_and_tests.patch"

	sed -i \
		-e '/GPLv2/d' \
		-e '/LICENSE/d' \
		-e "s|\$(install_doc_dir)/xsd|\$(install_doc_dir)/xsd-${PV}|" \
		-e "s|\$(install_doc_dir)/libxsd|\$(install_doc_dir)/libxsd-${PV}|" \
		makefile libxsd/makefile || die "sed failed"

	sed -i \
		-e "s|\$(install_doc_dir)/xsd|\$(install_doc_dir)/xsd-${PV}/html|" \
		documentation/makefile || die "sed failed"
}

use_yesno() {
	use $1 && echo "y" || echo "n"
}

src_compile() {
	mkdir -p \
		build/cxx/gnu \
		build/import/lib{boost,cult,backend-elements,xerces-c,xsd-frontend}

	cat >> build/configuration-dynamic.make <<- EOF
xsd_with_ace := $(use_yesno ace)
xsd_with_xdr := y
xsd_with_dbxml := $(use_yesno dbxml)
xsd_with_boost_date_time := y
xsd_with_boost_serialization := y
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

	cat >> build/import/libbackend-elements/configuration-dynamic.make <<- EOF
libbackend_elements_installed := y
	EOF

	cat >> build/import/libxerces-c/configuration-dynamic.make <<- EOF
libxerces_c_installed := y
	EOF

	cat >> build/import/libxsd-frontend/configuration-dynamic.make <<- EOF
libxsd_frontend_installed := y
	EOF

	emake || die "emake failed"
}

src_install() {
	emake install_prefix="${D}/usr" install || die "emake install failed"

	dodoc NEWS README

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r examples
	fi
}
