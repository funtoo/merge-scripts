# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=(python{3_4,3_5})

inherit python-single-r1 cmake-utils

if [[ "${PV}" == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/lpereira/${PN}.git"
else
	KEYWORDS=""
	SRC_URI="https://github.com/lpereira/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

DESCRIPTION="An experimental, scalable, high performance HTTP server"
HOMEPAGE="https://lwan.ws"

LICENSE="GPL-2"
SLOT="0"
IUSE="jemalloc sqlite sql test valgrind"

DEPEND="dev-util/cmake sys-libs/zlib"
RDEPEND="
	jemalloc? ( dev-libs/jemalloc )
	sqlite? ( dev-db/sqlite )
	sql? ( virtual/mysql )
	test?  ( dev-lang/lua dev-lang/python dev-python/requests[${PYTHON_USEDEP}] )
	valgrind? ( dev-util/valgrind )"
