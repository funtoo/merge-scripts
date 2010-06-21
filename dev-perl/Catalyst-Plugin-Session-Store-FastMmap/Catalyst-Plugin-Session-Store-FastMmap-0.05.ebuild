# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=KARMAN
inherit perl-module

DESCRIPTION="FastMmap session storage backend."

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	>=dev-perl/Cache-FastMmap-1.13
	>=dev-perl/Catalyst-Plugin-Session-0.09
	dev-perl/Path-Class
"
