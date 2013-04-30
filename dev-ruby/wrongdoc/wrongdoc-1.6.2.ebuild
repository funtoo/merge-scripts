# Distributed under the terms of the GNU General Public License v2

EAPI=5
USE_RUBY="ruby18 ruby19 jruby"


inherit ruby-fakegem eutils

DESCRIPTION="wrongdoc mangles an existing RDoc directory and makes any changes we feel like"
HOMEPAGE="http://bogomips.org/wrongdoc/"

LICENSE="Ruby MIT"
SLOT="0"
KEYWORDS="*"
IUSE=""

ruby_add_bdepend "
	dev-ruby/racc
	doc? ( >=dev-ruby/hoe-2.7.0 )
	test? (
		>=dev-ruby/hoe-2.7.0
		dev-ruby/minitest
	)"

ruby_add_rdepend "=dev-ruby/json-1* >=dev-ruby/json-1.4"

# This ebuild replaces rdoc in ruby-1.9.2 and later.
# ruby 1.8.6 is no longer supported.
RDEPEND="${RDEPEND}
	ruby_targets_ruby19? (
		>=dev-lang/ruby-1.9.2:1.9
	)
	ruby_targets_ruby18? (
		>=dev-lang/ruby-1.8.7:1.8
	)"


all_ruby_install() {
	all_fakegem_install

	for bin in rdoc ri; do
		ruby_fakegem_binwrapper $bin /usr/bin/$bin-2

		if use ruby_targets_ruby19; then
			ruby_fakegem_binwrapper $bin /usr/bin/${bin}19
			sed -i -e "1s/env ruby/ruby19/" \
				"${ED}/usr/bin/${bin}19" || die
		fi
	done
}
