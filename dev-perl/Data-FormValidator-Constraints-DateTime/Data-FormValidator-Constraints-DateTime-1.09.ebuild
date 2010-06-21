# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=WONKO
inherit perl-module

DESCRIPTION="D::FV constraints for dates and times"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/DateTime-0.23
	>=dev-perl/DateTime-Format-Strptime-1.00
	dev-perl/DateTime-Format-Builder
	>=dev-perl/Data-FormValidator-3.61
"

