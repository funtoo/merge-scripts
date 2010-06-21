# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=1

MODULE_AUTHOR=MDOOTSON
WX_GTK_VER="2.8"
inherit wxwidgets perl-module

DESCRIPTION="access IO of external processes via events"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND="dev-lang/perl
	x11-libs/wxGTK:2.8
	dev-perl/wxperl"

#SRC_TEST=do
