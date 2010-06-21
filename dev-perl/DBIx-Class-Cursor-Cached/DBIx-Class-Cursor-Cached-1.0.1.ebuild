# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MSTROUT
inherit perl-module

DESCRIPTION="cursor class with built-in caching support"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="sqlite"
DEPEND="
	>=dev-perl/DBIx-Class-0.08004
	dev-perl/Digest-SHA1
	dev-perl/Cache-Cache
"

