# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit perl-module

S=${WORKDIR}/WWW-Facebook-API-v0.4.10

DESCRIPTION="Perl interface to Facebook Platform API"
HOMEPAGE="http://search.cpan.org/search?query=WWW-Facebook-API&mode=dist"
SRC_URI="mirror://cpan/authors/id/U/UN/UNOBE/WWW-Facebook-API-v0.4.10.tar.gz"


IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="dev-perl/libwww-perl
	dev-perl/Crypt-SSLeay
	dev-perl/JSON-Any
	dev-lang/perl"
