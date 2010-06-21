# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/wxperl/wxperl-0.82.ebuild,v 1.1 2008/04/28 23:23:46 yuval Exp $

EAPI=1

MODULE_AUTHOR=MBARBON
MY_PN=Wx
MY_P=${MY_PN}-${PV}
S=${WORKDIR}/${MY_P}
WX_GTK_VER="2.8"
inherit wxwidgets perl-module

DESCRIPTION="Perl bindings for wxGTK"
HOMEPAGE="http://wxperl.sourceforge.net/"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~amd64 ~ia64 ~x86"
IUSE=""

DEPEND="x11-libs/wxGTK:2.8
	>=dev-perl/Alien-wxWidgets-0.25
	dev-lang/perl
	virtual/perl-Test-Harness
	>=virtual/perl-File-Spec-0.82"
