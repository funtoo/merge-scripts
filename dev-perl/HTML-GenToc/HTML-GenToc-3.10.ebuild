# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=RUBYKAT
inherit perl-module

DESCRIPTION="Generate a Table of Contents for HTML documents."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=virtual/perl-Getopt-Long-2.34
	>=dev-perl/HTML-LinkList-0.1501
	>=dev-perl/Getopt-ArgvFile-1.09
	>=dev-perl/HTML-SimpleParse-0.1
	dev-perl/HTML-Parser
"

