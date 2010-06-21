# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=ASH
inherit perl-module

DESCRIPTION="File based storage model for Catalyst."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/Catalyst-Runtime
	dev-perl/Catalyst-Component-InstancePerContext
	dev-perl/Path-Class
"
