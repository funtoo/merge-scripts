# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit subversion

DESCRIPTION="Ruby library for communicating with an MPD server"
HOMEPAGE="http://librmpd.rubyforge.org/"
ESVN_REPO_URI="svn://rubyforge.org/var/svn/librmpd/trunk"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE="doc"

DEPEND="${RDEPEND}
	>=dev-ruby/rubygems-0.8.4-r1
	dev-ruby/rake
	!dev-ruby/rdoc"
RDEPEND="!dev-ruby/librmpd
	virtual/ruby"

### This stuff is needed because of how messed up the ruby.eclass is. I should probably file a few bugs, but don't
### have time at the moment. Anything messes up please shoot me an email.

src_compile() {
	rake
}

gems_location() {
	local sitelibdir
	sitelibdir=`ruby -r rbconfig -e 'print Config::CONFIG["sitelibdir"]'`
	export GEMSDIR=${sitelibdir/site_ruby/gems}
}

src_install() {
	gems_location

	dodir "${GEMSDIR}"
	gem install "${S}/pkg/" -v "${PV}" \
		$(use doc && echo --rdoc || echo --no-rdoc) \
		-l -i "${D}/${GEMSDIR}" || die "gem install failed"
}
