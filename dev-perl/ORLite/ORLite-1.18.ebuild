# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

MODULE_AUTHOR=ADAMK
inherit perl-module

DESCRIPTION="Extremely light weight SQLite-specific ORM"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND="
	>=virtual/perl-File-Temp-0.17
	>=dev-perl/Params-Util-0.33
	>=dev-perl/DBI-1.58
	>=dev-perl/DBD-SQLite-1.14
"

SRC_TEST=do
