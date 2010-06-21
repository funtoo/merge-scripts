# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=BTROTT
inherit perl-module

DESCRIPTION="OpenID Authentication"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/LWPx-ParanoidAgent
	dev-perl/Net-OpenID-Consumer
	dev-perl/Catalyst-Runtime
"

