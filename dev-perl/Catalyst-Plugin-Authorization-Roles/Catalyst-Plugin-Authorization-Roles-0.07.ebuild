# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=BRICAS
inherit perl-module

DESCRIPTION="Role based authorization for Catalyst based on Catalyst::Plugin::Authentication"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/Catalyst-Runtime
	>=dev-perl/Catalyst-Plugin-Authentication-0.10003
	>=dev-perl/Set-Object-1.14
	>=dev-perl/UNIVERSAL-isa-0.05
"
