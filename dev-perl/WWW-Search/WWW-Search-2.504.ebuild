# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MODULE_AUTHOR=MTHURN
inherit perl-module

DESCRIPTION="Virtual base class for WWW searches"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/Date-Manip
	dev-perl/HTML-Parser
	>=dev-perl/HTML-Tree-0.51
	dev-perl/libwww-perl
	dev-perl/URI
	dev-perl/User
"
