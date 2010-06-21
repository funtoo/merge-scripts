# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=WONKO
inherit perl-module

DESCRIPTION="Easy manipulation of JSON headers"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/CGI-Application-4.00
	>=dev-perl/JSON-Any-1.14
	>=dev-perl/JSON-2.02
"
