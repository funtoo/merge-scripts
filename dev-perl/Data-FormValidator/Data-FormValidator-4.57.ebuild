# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MARKSTOS
inherit perl-module

DESCRIPTION="Validates user input (usually from an HTML form) based on input profile."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	virtual/perl-Module-Build
	dev-perl/ImageSize
	>=dev-perl/Date-Calc-5.0
	>=dev-perl/File-MMagic-1.17
	>=dev-perl/MIME-Types-1.005
	dev-perl/regexp-common
	>=dev-perl/Perl6-Junction-1.10
"

