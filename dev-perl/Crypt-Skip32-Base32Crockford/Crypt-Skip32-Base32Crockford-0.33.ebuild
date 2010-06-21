# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=LBROCARD
inherit perl-module

DESCRIPTION="Create url-safe encodings of 32-bit values"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	dev-perl/Crypt-Skip32
	dev-perl/Encode-Base32-Crockford
"
