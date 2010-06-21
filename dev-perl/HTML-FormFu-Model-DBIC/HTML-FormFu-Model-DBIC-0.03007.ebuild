# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CFRANKS
inherit perl-module

DESCRIPTION="HTML Form Creation, Rendering and Validation Framework"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/DateTime-Format-MySQL
	dev-perl/DBD-SQLite
	>=dev-perl/DBIx-Class-0.08002
	>=dev-perl/HTML-FormFu-0.03007
	dev-perl/Task-Weaken
"

