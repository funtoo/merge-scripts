# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=DKAMHOLZ
inherit perl-module

DESCRIPTION="Per user sessions (instead of per browser sessions)."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/Catalyst-Plugin-Session-0.01
	>=dev-perl/Catalyst-Plugin-Authentication-0.01
	dev-perl/Hash-Merge
	dev-perl/Object-Signature
"
