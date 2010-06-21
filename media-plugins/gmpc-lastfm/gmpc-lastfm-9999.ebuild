# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

GMPC_PLUGIN="last.fm"
inherit gmpc-plugin

DESCRIPTION="The last.fm plugin can fetch artist images, from last.fm. This plugin doesn't scrobble your music, use a dedicated client like mpdscribble for this."
LICENSE="GPL-2"
DEPEND="x11-libs/gtk+:2[jpeg]"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE=""
