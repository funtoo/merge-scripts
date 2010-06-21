# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=YANA
inherit perl-module

DESCRIPTION="Make it easy to use GD::Barcode in Catalyst's View."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/Catalyst-Runtime
	>=dev-perl/GD-Barcode-1.15
"
