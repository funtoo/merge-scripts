# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

MODULE_AUTHOR=ADAMK
inherit perl-module

DESCRIPTION='implementation of the "Adapter" Design Pattern'

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~x86"
IUSE="test"

RDEPEND="dev-lang/perl
	>=virtual/perl-Scalar-List-Utils-1.10"
DEPEND="${RDEPEND}
	test? ( virtual/perl-Test-Simple )"

SRC_TEST=do
