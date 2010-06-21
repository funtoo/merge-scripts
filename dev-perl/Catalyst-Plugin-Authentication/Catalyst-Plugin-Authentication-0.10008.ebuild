# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=JAYK
inherit perl-module

DESCRIPTION="Infrastructure plugin for the Catalyst authentication framework"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/Catalyst-Runtime
	dev-perl/Class-Inspector
	>=dev-perl/Catalyst-Plugin-Session-0.10
"

