# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=AGRUNDMA
inherit perl-module

DESCRIPTION="Realtime file upload information"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	virtual/perl-Module-Build
	dev-perl/Catalyst-Runtime
"

