# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CFRANKS
inherit perl-module

DESCRIPTION="DEPRECATED - use HTML::FormFu::Model::DBIC instead"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/DBIx-Class
	dev-perl/HTML-FormFu
"

