# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=DMAKI
inherit perl-module

DESCRIPTION="Dynamic definition of Class::DBI sub classes."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/Class-DBI-0.89
	>=dev-perl/DBI-1.30
	dev-perl/Lingua-EN-Inflect"
