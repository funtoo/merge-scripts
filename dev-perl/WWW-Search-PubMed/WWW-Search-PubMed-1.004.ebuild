# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MODULE_AUTHOR=GWILLIAMS
inherit perl-module

DESCRIPTION="Search the NCBI PubMed abstract database."

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/WWW-Search
	dev-perl/libwww-perl
	dev-perl/XML-DOM
"
