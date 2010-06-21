# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MRAMBERG
inherit perl-module

DESCRIPTION="Catalyst Development Tools"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/Class-Accessor
	>=dev-perl/Path-Class-0.09
	>=dev-perl/Template-Toolkit-2.14
	>=dev-perl/Catalyst-Runtime-5.7000
	>=dev-perl/Catalyst-Action-RenderView-0.04
	>=dev-perl/Catalyst-Plugin-Static-Simple-0.16
	dev-perl/Catalyst-Plugin-ConfigLoader
	dev-perl/parent
	>=dev-perl/yaml-0.55
	>=dev-perl/Module-Install-0.64
	dev-perl/File-Copy-Recursive
"

