# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=RKRIMEN
inherit perl-module

DESCRIPTION="JavaScript Templating with Template Toolkit"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/Template-Toolkit-2.19
	>=dev-perl/File-Find-Rule-0.30
"
