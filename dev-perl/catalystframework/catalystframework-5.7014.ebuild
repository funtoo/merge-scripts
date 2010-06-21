# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

DESCRIPTION="Meta package for Catalyst - The Elegant MVC Web Application
Framework, and all the plugins you need to get started"
HOMEPAGE="http://www.catalystframework.org/"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~amd64 ~x86"

S=${WORKDIR}

IUSE=""
DEPEND="
	>=dev-perl/Task-Catalyst-2.0001
	dev-perl/Catalyst-Manual
"
