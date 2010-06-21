# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CLACO
inherit perl-module

DESCRIPTION="Validate all data before submitting to your database."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/DBIx-Class-0.07005
	>=dev-perl/FormValidator-Simple-0.17
"
