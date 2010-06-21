# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CREAMYG
inherit perl-module

DESCRIPTION="Perl interface to Snowball stemmers."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	virtual/perl-ExtUtils-CBuilder
	virtual/perl-ExtUtils-ParseXS
"

