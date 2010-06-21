# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=BRICAS
inherit perl-module

DESCRIPTION="Automatic inflation/deflation of epoch-based DateTime objects for DBIx::Class"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/DateTime
	dev-perl/DBIx-Class
"

