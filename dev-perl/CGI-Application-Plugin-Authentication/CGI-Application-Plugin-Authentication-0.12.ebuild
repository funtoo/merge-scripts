# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CEESHEK
inherit perl-module

DESCRIPTION="Authentication framework for CGI::Application"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/CGI-Application-4
	dev-perl/Digest-SHA1
	dev-perl/UNIVERSAL-require
	dev-perl/Test-Warn
	dev-perl/Test-Exception
"
