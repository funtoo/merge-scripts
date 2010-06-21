# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header $

inherit perl-module

DESCRIPTION="Netscape bookmarks"
HOMEPAGE="http://search.cpan.org/dist/Netscape-Bookmarks/"
SRC_URI="http://search.cpan.org/CPAN/authors/id/B/BD/BDFOY/Netscape-Bookmarks-1.95.tar.gz"

LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~x86 ~amd64"
SLOT="0"

DEPEND="
    dev-lang/perl
    dev-perl/HTML-Parser
    dev-perl/URI"

DEPEND="${RDEPEND}"
