# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit gmpc-plugin

DESCRIPTION="A GMPC plugin to interface jamendo.com API"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
DEPEND="dev-libs/libxml
	dev-db/sqlite
	sys-libs/zlib"
RDEPEND="${DEPEND}"
