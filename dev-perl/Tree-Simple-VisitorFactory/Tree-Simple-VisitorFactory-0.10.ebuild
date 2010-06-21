# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=STEVAN
inherit perl-module

DESCRIPTION="A factory object for dispensing Visitor objects"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND=">=perl-core/Test-Simple-0.47
	>=dev-perl/Test-Exception-0.15
	>=dev-perl/Tree-Simple-1.12"
