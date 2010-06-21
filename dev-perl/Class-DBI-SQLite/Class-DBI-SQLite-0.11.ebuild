# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MIYAGAWA
inherit perl-module

DESCRIPTION="Extension to Class::DBI for sqlite"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/Class-DBI-0.85
	>=dev-perl/Ima-DBI-0.27
	>=dev-perl/DBD-SQLite-0.07"
