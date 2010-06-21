# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=JAYK
inherit perl-module

DESCRIPTION="Authentication and authorization against a DBIx::Class schema"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/Catalyst-Runtime
	>=dev-perl/Catalyst-Plugin-Authentication-0.10005
	dev-perl/DBIx-Class
	dev-perl/Catalyst-Model-DBIC-Schema
"
