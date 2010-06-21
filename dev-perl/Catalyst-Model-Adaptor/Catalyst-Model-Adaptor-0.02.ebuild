# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=JROCKWAY
inherit perl-module

DESCRIPTION="helper for the incredibly lazy"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/Class-C3
	dev-perl/Catalyst-Runtime
"
