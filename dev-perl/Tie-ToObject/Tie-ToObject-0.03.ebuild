# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Tie-ToObject/Tie-ToObject-0.03.ebuild,v 1.1 2009/10/10 12:10:10 tove Exp $

EAPI=2

MODULE_AUTHOR=NUFFIN
inherit perl-module

DESCRIPTION="Tie to an existing object."

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

RDEPEND=""
DEPEND="test? ( dev-perl/Test-use-ok )"

SRC_TEST=do
