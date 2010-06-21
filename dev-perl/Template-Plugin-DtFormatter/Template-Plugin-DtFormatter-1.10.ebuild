# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=ARTHAS
inherit perl-module

DESCRIPTION="Easily create formatted string from DateTime objects"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	virtual/perl-Module-Build
	>=dev-perl/Template-Toolkit-2.15
	>=dev-perl/DateTime-0.32
	>=dev-perl/DateTime-Format-Strptime-1.0700
"
