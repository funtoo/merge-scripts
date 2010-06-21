# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MODULE_AUTHOR=UNOBE
inherit perl-module

DESCRIPTION="Perl interface to Facebook Platform API"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	virtual/perl-version
	dev-perl/Crypt-SSLeay
	dev-perl/JSON-Any
	dev-perl/libwww-perl
	dev-perl/Readonly
"
