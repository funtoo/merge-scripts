# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=AGENT
inherit perl-module

DESCRIPTION="(DEPRECATED) HTTP Cookie parser in C (Please use CGI::Cookie::XS
instead)"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/CGI-Cookie-XS-0.15
"

pkg_setup() {
	ewarn "This ebuild is DEPRECATED and will be removed."
	ewarn "Please use CGI-Cookie-XS!!!"
}

