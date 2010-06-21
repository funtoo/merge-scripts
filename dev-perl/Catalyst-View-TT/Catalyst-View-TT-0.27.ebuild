# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MRAMBERG
inherit perl-module

DESCRIPTION="Template View Class"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/Catalyst-Runtime
	dev-perl/Template-Toolkit
	dev-perl/Class-Accessor
	dev-perl/Template-Timer
	dev-perl/Path-Class
"
