# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CREAMYG
inherit perl-module

DESCRIPTION="search engine library"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	virtual/perl-Module-Build
	virtual/perl-Compress-Zlib
	>=dev-perl/Lingua-Stem-Snowball-0.94
	>=dev-perl/Lingua-StopWords-0.02
"

