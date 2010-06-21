
MY_P="defunkt-github-${PV}"
inherit gems

DESCRIPTION="The official github command line helper for simplifying your GitHub experience."
HOMEPAGE="http://github.com"
SRC_URI="http://gems.github.com/gems/${MY_P}.gem"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="dev-ruby/json_pure
>=dev-ruby/rubygems-1.3.0"
RDEPEND="${DEPEND}"

