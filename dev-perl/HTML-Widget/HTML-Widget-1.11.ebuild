# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CFRANKS
inherit perl-module

DESCRIPTION="HTML Widget And Validation Framework"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-lang/perl-5.8.1
	dev-perl/Module-Install
	>=dev-perl/HTML-Tree-3.23
	dev-perl/Class-Accessor
	dev-perl/Class-Accessor-Chained
	dev-perl/Class-Data-Accessor
	dev-perl/HTML-Scrubber
	dev-perl/Module-Pluggable-Fast
	dev-perl/Email-Valid
	dev-perl/Date-Calc
	dev-perl/Test-NoWarnings
"
