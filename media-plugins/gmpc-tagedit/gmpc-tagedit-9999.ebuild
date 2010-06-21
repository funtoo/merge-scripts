# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit gmpc-plugin

DESCRIPTION="This plugin allows you to tag your music collection."
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
DEPEND="media-libs/taglib"

pkg_postinst() {
	elog "This plugin is extremely alpha. Use with caution (and realize there won't be errors, yet)"
}
