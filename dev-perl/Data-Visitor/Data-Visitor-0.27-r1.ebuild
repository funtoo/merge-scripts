# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Data-Visitor/Data-Visitor-0.27-r1.ebuild,v 1.1 2010/05/28 07:50:41 tove Exp $

EAPI=2

MODULE_AUTHOR=FLORA
inherit perl-module

DESCRIPTION="A visitor for Perl data structures"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

RDEPEND="
	>=dev-perl/Moose-0.89
	>=dev-perl/namespace-clean-0.08
	>=dev-perl/Tie-ToObject-0.01
"
DEPEND="${RDEPEND}
	test? ( dev-perl/Test-use-ok )"

SRC_TEST="do"
