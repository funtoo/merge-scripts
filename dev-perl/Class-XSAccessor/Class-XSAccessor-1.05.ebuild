# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Class-XSAccessor/Class-XSAccessor-1.05.ebuild,v 1.3 2009/12/23 17:41:17 grobian Exp $

EAPI=2

MODULE_AUTHOR=SMUELLER
inherit perl-module

DESCRIPTION="Generate fast XS accessors without runtime compilation"

SLOT="0"
KEYWORDS="~amd64 ~x86 ~x86-solaris"
IUSE=""

DEPEND=">=dev-perl/AutoXS-Header-1.01"
RDEPEND="${DEPEND}
	!dev-perl/Class-XSAccessor-Array"

SRC_TEST=do
