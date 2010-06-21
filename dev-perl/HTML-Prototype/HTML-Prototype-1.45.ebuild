# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=ESSKAR
inherit perl-module

DESCRIPTION="Generate HTML and Javascript for the Prototype library"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="virtual/perl-Module-Build
	dev-perl/Class-Accessor
	dev-perl/HTML-Tree"
