# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=APEIRON
inherit perl-module

DESCRIPTION="Call module plugins in a specified order"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=virtual/perl-Module-Pluggable-1.9
	dev-perl/UNIVERSAL-require
"
