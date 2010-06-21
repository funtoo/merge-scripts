# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/wxperl/wxperl-0.91.ebuild,v 1.6 2010/04/09 07:08:14 tove Exp $

EAPI=2

MODULE_AUTHOR=MBARBON
MY_PN=Wx
MY_P=${MY_PN}-${PV}
S=${WORKDIR}/${MY_P}
WX_GTK_VER="2.8"
inherit wxwidgets perl-module

DESCRIPTION="Perl bindings for wxGTK"
HOMEPAGE="http://wxperl.sourceforge.net/"

SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RDEPEND="x11-libs/wxGTK:2.8
	>=dev-perl/Alien-wxWidgets-0.25
	>=virtual/perl-File-Spec-0.82"
DEPEND="${RDEPEND}"

MAKEOPTS="${MAKEOPTS} -j1"
