# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=1

MODULE_AUTHOR=SZABGAB
WX_GTK_VER="2.8"
inherit wxwidgets perl-module

DESCRIPTION="Abstract dialog class for simple dialog creation"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

RDEPEND="dev-lang/perl
	x11-libs/wxGTK:2.8
	dev-perl/File-Copy-Recursive
	dev-perl/Wx-Perl-ProcessStream"
DEPEND="${RDEPEND}"

SRC_TEST=do
