# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MSISK
inherit perl-module

DESCRIPTION="DateTime extension for generating recurrence sets from crontab
lines and files."

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND=">=dev-perl/DateTime-0.21
	>=dev-perl/DateTime-Set-0.14.06
	dev-perl/Set-Crontab"
