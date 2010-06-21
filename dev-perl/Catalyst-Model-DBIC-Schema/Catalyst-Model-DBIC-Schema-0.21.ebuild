# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=BOGDAN
inherit perl-module

DESCRIPTION="DBIx::Class::Schema Model Class"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/DBIx-Class-0.07006
	dev-perl/Catalyst-Runtime
	>=dev-perl/UNIVERSAL-require-0.10
	>=dev-perl/Class-Data-Accessor-0.02
	>=dev-perl/Class-Accessor-0.22
	>=dev-perl/Catalyst-Devel-1.0
	>=dev-perl/DBIx-Class-Schema-Loader-0.03012
"
