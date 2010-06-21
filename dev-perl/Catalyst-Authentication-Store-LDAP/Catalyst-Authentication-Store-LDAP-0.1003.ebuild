# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=KARMAN
inherit perl-module

DESCRIPTION="Authentication from an LDAP Directory."

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/perl-ldap
	>=dev-perl/Catalyst-Plugin-Authentication-0.10003
"
