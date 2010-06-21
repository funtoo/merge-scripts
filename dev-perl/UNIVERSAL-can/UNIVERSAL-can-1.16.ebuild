# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/UNIVERSAL-can/UNIVERSAL-can-1.16.ebuild,v 1.1 2010/01/16 21:00:43 tove Exp $

EAPI=2

MODULE_AUTHOR=CHROMATIC
inherit perl-module

DESCRIPTION="Hack around people calling UNIVERSAL::can() as a function"

LICENSE="Artistic-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

RDEPEND="virtual/perl-Scalar-List-Utils"
DEPEND="
	>=virtual/perl-Module-Build-0.35
	test? (
		${RDEPEND}
		>=virtual/perl-Test-Simple-0.60
	)"

SRC_TEST="do"
