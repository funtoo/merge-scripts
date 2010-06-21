# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
EAPI=2

inherit distutils subversion

DESCRIPTION="an elegant GTK+ music client for the Music Player Daemon (MPD)."
HOMEPAGE="http://sonata.berlios.de/"
ESVN_REPO_URI="http://svn.berlios.de/svnroot/repos/sonata/trunk"

LICENSE="GPL-3"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE="taglib lyrics dbus scrobbler"

RDEPEND=">=virtual/python-2.4
	>=dev-python/pygtk-2.10
	taglib? ( >=dev-python/tagpy-0.93 )
	dbus? ( dev-python/dbus-python )
	lyrics? ( dev-python/zsi )
	scrobbler? ( dev-python/elementtree )
	x11-libs/gtk+:2[jpeg]"

DOCS="CHANGELOG README TODO TRANSLATORS"
