# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MAB
inherit perl-module

DESCRIPTION="Add Config::Any Support to CGI::Application"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	virtual/perl-Module-Build
	>=dev-perl/Config-Any-0.08
	>=dev-perl/CGI-Application-4.10
"
