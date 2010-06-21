# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=NUFFIN
inherit perl-module

DESCRIPTION="A lightweight Crypt/Digest convenience API"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/Perl6-Junction
	dev-perl/Module-Compile-TT
	dev-perl/Class-Accessor
	dev-perl/Sub-Exporter
	dev-perl/crypt-cbc
	dev-perl/Crypt-Rijndael
	virtual/perl-Digest-SHA
"
