# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=NUFFIN
inherit perl-module

DESCRIPTION="Infrastructure plugin for the Catalyst authentication framework"
HOMEPAGE="http://www.cpan.org/modules/by-authors/id/N/NU/NUFFIN/${P}.readme"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/Catalyst-Runtime
	>=dev-perl/Catalyst-Plugin-Authentication-0.03
	>=dev-perl/Set-Object-1.14
	dev-perl/Test-Exception
	>=dev-perl/Test-MockObject-1.01
	>=dev-perl/UNIVERSAL-isa-0.05
"
