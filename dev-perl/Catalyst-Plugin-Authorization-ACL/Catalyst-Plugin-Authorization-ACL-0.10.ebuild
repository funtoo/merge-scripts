# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=RKITOVER
inherit perl-module

DESCRIPTION="ACL support for Catalyst applications"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/Catalyst-Runtime
	dev-perl/Class-Data-Inheritable
	dev-perl/Class-Throwable
	dev-perl/Tree-Simple-VisitorFactory
"

