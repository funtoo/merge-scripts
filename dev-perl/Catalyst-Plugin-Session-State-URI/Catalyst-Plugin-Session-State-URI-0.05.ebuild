# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=NUFFIN
inherit perl-module

DESCRIPTION="Saves session IDs by rewriting URIs delivered to the client, and extracting the session ID from requested URIs"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/Catalyst-Plugin-Session-0.06
	dev-perl/HTML-TokeParser-Simple
	>=dev-perl/Test-MockObject-1.01
	dev-perl/MIME-Types
	dev-perl/URI
"
