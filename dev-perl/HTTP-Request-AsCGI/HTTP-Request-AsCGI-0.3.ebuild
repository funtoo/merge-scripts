# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CHANSEN
inherit perl-module

DESCRIPTION="Setup a CGI enviroment from a HTTP::Request"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="dev-perl/Class-Accessor
	dev-perl/libwww-perl"
