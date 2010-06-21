# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=ANDYA
inherit perl-module

DESCRIPTION="A Perl implementation of the reCAPTCHA API"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/libwww-perl
	>=dev-perl/HTML-Tiny-0.904
"

