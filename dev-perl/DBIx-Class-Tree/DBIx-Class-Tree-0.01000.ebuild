# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=BLUEFEET
inherit perl-module

DESCRIPTION="Manipulate and anaylze tree structured data. (EXPERIMENTAL)"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	virtual/perl-Module-Build
	>=dev-perl/DBIx-Class-0.06
"
