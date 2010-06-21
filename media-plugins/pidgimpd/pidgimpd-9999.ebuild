# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=2

ESVN_REPO_URI="https://svn.ayeon.org/pidgimpd/trunk/"
inherit subversion autotools

DESCRIPTION="A gaim plugin for MPD"
HOMEPAGE="http://ayeon.org/projects/pidgimpd/"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT=0

IUSE="debug"

DEPEND="net-im/pidgin"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf $(use_enable debug) || 'Configure failed.'
}

src_install() {
	emake install DESTDIR=${D} || die
}
