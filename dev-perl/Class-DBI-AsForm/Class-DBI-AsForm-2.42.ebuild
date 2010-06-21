# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=TMTM
inherit perl-module

DESCRIPTION="Produce HTML form elements for database columns"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/Class-DBI-0.94
	>=dev-perl/DBI-1.21
	dev-perl/HTML-Tree
	dev-perl/Class-DBI-Plugin-Type
"
