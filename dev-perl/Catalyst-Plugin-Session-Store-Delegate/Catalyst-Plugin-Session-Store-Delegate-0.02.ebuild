# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=NUFFIN
inherit perl-module

DESCRIPTION="Delegate session storage to an application model object."
HOMEPAGE="http://search.cpan.org/dist/${P}/"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	>=dev-perl/Catalyst-Plugin-Session-0.12
	dev-perl/Class-Accessor
	dev-perl/Test-use-ok
"
