# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=JROBINSON
inherit perl-module

DESCRIPTION="Flexible caching support for Catalyst"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	>=dev-perl/Catalyst-Runtime-5.7
	dev-perl/Task-Weaken
	dev-perl/Test-Deep
	dev-perl/Test-Exception
"

