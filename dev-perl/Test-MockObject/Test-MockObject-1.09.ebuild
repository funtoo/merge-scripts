# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Test-MockObject/Test-MockObject-1.09.ebuild,v 1.2 2010/02/03 11:14:24 tove Exp $

EAPI=2

MODULE_AUTHOR=CHROMATIC
inherit perl-module

DESCRIPTION="Perl extension for emulating troublesome interfaces"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

RDEPEND=">=dev-perl/UNIVERSAL-isa-0.06
	>=dev-perl/UNIVERSAL-can-1.11"
DEPEND="${RDEPEND}
	virtual/perl-Module-Build
	test? ( dev-perl/Test-Exception )"

SRC_TEST=do
