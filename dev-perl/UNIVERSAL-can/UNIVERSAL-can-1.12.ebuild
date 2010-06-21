# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CHROMATIC
inherit perl-module

DESCRIPTION="Hack around people calling UNIVERSAL::can() as a function"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="virtual/perl-Module-Build
	>=dev-lang/perl-5.6.0"
