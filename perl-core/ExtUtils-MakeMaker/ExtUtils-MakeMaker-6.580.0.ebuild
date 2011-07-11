# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/perl-core/ExtUtils-MakeMaker/ExtUtils-MakeMaker-6.580.0.ebuild,v 1.2 2011/07/11 09:59:28 tove Exp $

EAPI=4
MODULE_VERSION="6.58"
MODULE_AUTHOR=MSCHWERN
inherit eutils perl-module

DESCRIPTION="Create a module Makefile"
HOMEPAGE="http://makemaker.org ${HOMEPAGE}"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~sparc ~x86"
IUSE=""

DEPEND="
	>=virtual/perl-ExtUtils-Command-1.16
	>=virtual/perl-ExtUtils-Install-1.52
	>=virtual/perl-ExtUtils-Manifest-1.58
	>=virtual/perl-File-Spec-0.8
"
RDEPEND="${DEPEND}
	!!<dev-lang/perl-5.8.8-r7"
PDEPEND="
	>=virtual/perl-Parse-CPAN-Meta-1.440.100
"

PATCHES=(
	"${FILESDIR}/6.58-delete_packlist_podlocal.patch"
	"${FILESDIR}/6.58-RUNPATH.patch"
)
SRC_TEST=do

src_prepare (){
	edos2unix "${S}/lib/ExtUtils/MM_Unix.pm"
	edos2unix "${S}/lib/ExtUtils/MM_Any.pm"

	perl-module_src_prepare
}

src_install() {
	perl-module_src_install

	# remove all the bundled distributions
	pushd "${D}" >/dev/null
	find ".${VENDOR_LIB}" -mindepth 1 -maxdepth 1 -not -name "ExtUtils" -exec rm -rf {} \+
	popd >/dev/null
}
