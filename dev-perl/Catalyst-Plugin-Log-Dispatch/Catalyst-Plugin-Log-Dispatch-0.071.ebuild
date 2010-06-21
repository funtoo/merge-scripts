# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=SHOT
inherit perl-module

DESCRIPTION="Log module of Catalyst that uses Log::Dispatch"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/log-dispatch-2.13
	>=dev-perl/Catalyst-Runtime-5.65
	dev-perl/UNIVERSAL-require
"
