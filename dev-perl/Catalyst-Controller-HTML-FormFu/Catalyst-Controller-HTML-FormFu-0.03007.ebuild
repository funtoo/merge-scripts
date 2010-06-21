# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CFRANKS
inherit perl-module

DESCRIPTION="Catalyst controller for HTML::FormFu framework"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/Catalyst-Runtime-5.70
	dev-perl/Catalyst-Component-InstancePerContext
	dev-perl/Config-Any
	>=dev-perl/HTML-FormFu-0.03007
	dev-perl/Moose
	dev-perl/Regexp-Assemble
	dev-perl/Task-Weaken
"

