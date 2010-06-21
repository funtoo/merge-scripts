# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MRAMBERG
inherit perl-module

DESCRIPTION="Send emails with Catalyst"
HOMEPAGE="http://searc.cpan.org/dist/${PN}/"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/Catalyst-Runtime
	dev-perl/Email-Send
	dev-perl/Email-MIME
	dev-perl/Email-MIME-Creator
"
