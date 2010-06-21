# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MODULE_AUTHOR=MIYAGAWA
inherit perl-module

DESCRIPTION="Plugin for CGI::Untaint for email"
HOMEPAGE="http://search.cpan.org/search?query=CGI-Untaint-email&mode=dist"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND=">=dev-perl/CGI-Untaint-1.26
	>=dev-perl/Email-Valid-0.179
	>=dev-perl/MailTools-1.77"
