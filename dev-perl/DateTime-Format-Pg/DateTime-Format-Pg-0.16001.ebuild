# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=DMAKI
inherit perl-module

DESCRIPTION="Parse and format PostgreSQL dates and times"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	>=dev-perl/DateTime-0.10
	>=dev-perl/DateTime-Format-Builder-0.72
	>=dev-perl/DateTime-TimeZone-0.05
"

