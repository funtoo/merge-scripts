# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=ILMARI
inherit perl-module

DESCRIPTION="Dynamic definition of DBIx::Class sub classes."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="sqlite mysql postgres db2 oracle"
DEPEND="
	>=dev-perl/Data-Dump-1.06
	>=dev-perl/UNIVERSAL-require-0.11
	>=dev-perl/Lingua-EN-Inflect-Number-1.1
	>=dev-perl/Class-Accessor-0.30
	>=dev-perl/Class-Data-Accessor-0.03
	>=dev-perl/Class-C3-0.18
	>=dev-perl/DBIx-Class-0.07006
	dev-perl/Class-Inspector
	>=dev-perl/DBI-1.56
	sqlite? ( >=dev-perl/DBD-SQLite-1.12 )
	mysql? ( >=dev-perl/DBD-mysql-4.00.4 )
	postgres? ( >=dev-perl/DBD-Pg-1.49 )
	db2? ( >=dev-perl/DBD-DB2-1.0 )
	oracle? ( >=dev-perl/DBD-Oracle-0.19 )
"
