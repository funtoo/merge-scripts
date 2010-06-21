# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header $

inherit perl-module versionator

MY_PN=$(echo ${PN%-*})
MY_PV=$(replace_version_separator 2 '_')

DESCRIPTION="Netscape Bookmarks"
HOMEPAGE="http://sourceforge.net/projects/nsbookmarks/"
SRC_URI="http://downloads.sourceforge.net/nsbookmarks/${MY_PN}-${MY_PV}.tar.gz"

LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~x86 ~amd64"
SLOT="0"

DEPEND="
    dev-lang/perl
    dev-perl/HTML-Parser
    dev-perl/URI"

DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_PN}-${MY_PV}"
