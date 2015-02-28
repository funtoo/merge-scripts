# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit multilib toolchain-funcs

DESCRIPTION="Lua binding for OpenSSL library to provide TLS/SSL communication"
HOMEPAGE="https://github.com/brunoos/luasec http://www.inf.puc-rio.br/~brunoos/luasec/"
SRC_URI="https://github.com/brunoos/luasec/archive/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~*"
IUSE=""

S=${WORKDIR}/${PN}-${P}

RDEPEND=">=dev-lang/lua-5.1[deprecated]
		dev-lua/luasocket
		dev-libs/openssl[-bindist]"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	sed -i -e "s#^LUAPATH.*#LUAPATH=$(pkg-config --variable INSTALL_LMOD lua)#"\
		-e "s#^LUACPATH.*#LUACPATH=$(pkg-config --variable INSTALL_CMOD lua)#" Makefile || die
	sed -i -e "s/-O2//" src/Makefile || die
	lua src/options.lua -g /usr/include/openssl/ssl.h > src/options.h || die
}

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		LD="$(tc-getCC)" \
		linux
}

src_install() {
	emake DESTDIR="${D}" install
}
