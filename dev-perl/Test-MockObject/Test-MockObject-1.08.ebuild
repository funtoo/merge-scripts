# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CHROMATIC
inherit perl-module

DESCRIPTION="Perl extension for emulating troublesome interfaces"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="virtual/perl-Module-Build
	>=dev-lang/perl-5.6.0
	>=dev-perl/UNIVERSAL-isa-0.06
	>=dev-perl/UNIVERSAL-can-1.11
	dev-perl/Test-Exception"
