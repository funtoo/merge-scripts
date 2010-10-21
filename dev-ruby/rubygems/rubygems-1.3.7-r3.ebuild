# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-ruby/rubygems/rubygems-1.3.7-r3.ebuild,v 1.3 2010/08/18 10:29:35 flameeyes Exp $

EAPI="3"

USE_RUBY="ruby18 ruby19 ree18 jruby"

inherit ruby-ng prefix

DESCRIPTION="Centralized Ruby extension management system"
HOMEPAGE="http://rubyforge.org/projects/rubygems/"
LICENSE="|| ( Ruby GPL-2 )"

SRC_URI="mirror://rubyforge/${PN}/${P}.tgz"

KEYWORDS="~amd64 ~arm ~hppa ~ia64 ~mips ~ppc64 ~s390 ~sparc ~x86 ~x86-fbsd"
SLOT="0"
IUSE="server test"

RDEPEND="
	ruby_targets_jruby? ( >=dev-java/jruby-1.4.0-r5 )
	ruby_targets_ruby19? ( >=dev-lang/ruby-1.9.2_rc2 )"

# index_gem_repository.rb
PDEPEND="server? ( dev-ruby/builder[ruby_targets_ruby18] )"

# Tests fail _badly_ when YARD is installed.. but just the
# rdoc-related stuff, so it's not a mistake.
ruby_add_bdepend "
	test? (
		dev-ruby/minitest
		virtual/ruby-rdoc
		!dev-ruby/yard
		!dev-ruby/test-unit:2
	)"

# Until all the JRuby tests' failures are sorted out
RESTRICT="ruby_targets_jruby? ( test )"

RUBY_PATCHES=(
	"${FILESDIR}/${P}-gentoo.patch"
)

all_ruby_prepare() {
	mkdir -p lib/rubygems/defaults || die
	cp "${FILESDIR}/gentoo-defaults.rb" lib/rubygems/defaults/operating_system.rb || die

	eprefixify lib/rubygems/defaults/operating_system.rb

	# Disable broken tests when changing default values:
	sed -i -e '/^  def test_self_bindir_default_dir/, /^  end/ s:^:#:' \
		-e '/^  def test_self_default_dir/, /^  end/ s:^:#:' \
		test/test_gem.rb || die
}

each_ruby_compile() {
	# Not really a build but...
	sed -i -e 's:#!.*:#!'"${RUBY}"':' bin/gem
}

each_ruby_test() {
	# Unset RUBYOPT to avoid interferences, bug #158455 et. al.
	unset RUBYOPT

	RUBYLIB="$(pwd)/lib${RUBYLIB+:${RUBYLIB}}" ${RUBY} -Ilib:test \
		-e 'Dir["./test/test_*.rb"].each { |tu| require tu }' || die "tests failed"
}

each_ruby_install() {
	# Unset RUBYOPT to avoid interferences, bug #158455 et. al.
	unset RUBYOPT

	pushd lib &>/dev/null
	doruby -r *
	popd &>/dev/null

	case "${RUBY}" in
		*ruby19)
			insinto $(ruby_rbconfig_value 'sitelibdir')
			newins "${FILESDIR}/auto_gem.rb.ruby19" auto_gem.rb || die
			;;
		*)
			doruby "${FILESDIR}/auto_gem.rb" || die
			;;
	esac

	newbin bin/gem $(basename ${RUBY} | sed -e 's:ruby:gem:') || die
}

all_ruby_install() {
	dodoc README || die "dodoc README failed"

	doenvd "${FILESDIR}/10rubygems" || die "doenvd 10rubygems failed"

	if use server; then
		newinitd "${FILESDIR}/init.d-gem_server2" gem_server || die "newinitd failed"
		newconfd "${FILESDIR}/conf.d-gem_server" gem_server || die "newconfd failed"
	fi
}

pkg_postinst() {
	if [[ ! -n $(readlink "${ROOT}"usr/bin/gem) ]] ; then
		eselect ruby set $(eselect --brief --no-color ruby show | head -n1)
	fi

	ewarn
	ewarn "To switch between available Ruby profiles, execute as root:"
	ewarn "\teselect ruby set ruby(18|19|...)"
	ewarn
}

pkg_postrm() {
	ewarn "If you have uninstalled dev-ruby/rubygems, Ruby applications are unlikely"
	ewarn "to run in current shells because of missing auto_gem."
	ewarn "Please run \"unset RUBYOPT\" in your shells before using ruby"
	ewarn "or start new shells"
	ewarn
	ewarn "If you have not uninstalled dev-ruby/rubygems, please do not unset "
	ewarn "RUBYOPT"
}
