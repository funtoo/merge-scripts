# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=BLBLACK
inherit perl-module

DESCRIPTION="Dynamic definition of DBIx::Class sub classes."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/DBIx-Class-0.04001
	>=dev-perl/DBI-1.30
	dev-perl/Lingua-EN-Inflect
	>=dev-perl/UNIVERSAL-require-0.10"
