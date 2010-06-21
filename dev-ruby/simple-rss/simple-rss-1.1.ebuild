# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit ruby gems

USE_RUBY="ruby18"
DESCRIPTION="A simple, flexible, extensible, and liberal RSS and Atom reader for Ruby."
HOMEPAGE="http://rubyforge.org/projects/simple-rss"
SRC_URI="http://gems.rubyforge.org/gems/${P}.gem"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND=">=dev-lang/ruby-1.8.4"
RDEPEND="${DEPEND}"
