# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/simple-rss/simple-rss-1.2.2.ebuild,v 1.1 2009/12/18 17:50:45 graaff Exp $

EAPI=2
USE_RUBY="ruby18"

inherit ruby-fakegem

DESCRIPTION="Simple RSS is a simple, flexible, extensible, and liberal RSS and
Atom reader for Ruby."
HOMEPAGE="http://simple-rss.rubyforge.org/"
LICENSE="LGPL-2"

KEYWORDS="~x86 ~amd64"
SLOT="0"
IUSE=""

all_ruby_install() {
	dodoc README
}
