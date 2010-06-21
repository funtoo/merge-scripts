# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit perl-module

S=${WORKDIR}/Catalyst-Plugin-Facebook-0.1

DESCRIPTION="Catalyst plugin for Facebook Platform API integration"
HOMEPAGE="http://search.cpan.org/search?query=Catalyst-Plugin-Facebook&mode=dist"
SRC_URI="mirror://cpan/authors/id/S/SO/SOCK/Catalyst-Plugin-Facebook-0.1.tar.gz"


IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="dev-perl/WWW-Facebook-API
	dev-lang/perl"
