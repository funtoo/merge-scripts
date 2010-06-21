# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MRAMBERG
inherit perl-module

DESCRIPTION="Sensible default end action."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="virtual/perl-Module-Build
	>=dev-perl/Catalyst-5.2"
