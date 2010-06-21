# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=KARMAN
inherit perl-module

DESCRIPTION="File storage backend for session data"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	>=dev-perl/Class-Data-Inheritable-0.04
	>=dev-perl/Catalyst-Runtime-5.7000
	>=dev-perl/Cache-Cache-1.02
	dev-perl/Catalyst-Plugin-Session
"
