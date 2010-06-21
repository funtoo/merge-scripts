# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit ruby

DESCRIPTION="Ruby class for communicating with an MPD server"
HOMEPAGE="http://rubyforge.org/projects/mpd/"
SRC_URI="http://rubyforge.org/frs/download.php/8040/${P}.tar.gz"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE=""
RESTRICT="mirror"

RDEPEND="virtual/ruby"
