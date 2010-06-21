# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CORION
inherit perl-module

DESCRIPTION="checks intelligently if files have changed"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""

pkg_setup() {
	perl -MDigest -e1 || ewarn "File::Modified likes to have Digest, but doesn't require it."
	perl -MDigest::MD5 -e1 || ewarn "File::Modified likes to have Digest, but doesn't require it."
}
