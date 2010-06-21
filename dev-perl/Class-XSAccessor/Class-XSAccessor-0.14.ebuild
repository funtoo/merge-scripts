# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

MODULE_AUTHOR=SMUELLER
inherit perl-module

DESCRIPTION="Generate fast XS accessors without runtime compilation"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND="dev-lang/perl
	dev-perl/AutoXS-Header"

SRC_TEST=do
