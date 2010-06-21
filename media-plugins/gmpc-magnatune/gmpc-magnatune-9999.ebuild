# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit gmpc-plugin

DESCRIPTION="The plugin allows you to browse, and preview available albums on www.magnatune.com."
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
DEPEND="x11-libs/gtk+:2[jpeg]
	dev-libs/libxml
	dev-db/sqlite"
RDEPEND="${DEPEND}"
