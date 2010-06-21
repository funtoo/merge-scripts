# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MSTROUT
inherit perl-module

DESCRIPTION="Unmaintained, dangerous proof of concept"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/Array-RefElem
	dev-perl/Catalyst-Runtime
	dev-perl/Devel-Caller
	dev-perl/Devel-LexAlias
	dev-perl/PadWalker
	dev-perl/Test-use-ok
"

