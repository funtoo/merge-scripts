# Distributed under the terms of the GNU General Public License v2

EAPI=5-progress

PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.* *-jython *-pypy-*"
RESTRICT="test"

inherit python eutils multilib pax-utils

DESCRIPTION="Evented IO for V8 Javascript"
HOMEPAGE="http://nodejs.org/"
SRC_URI="http://nodejs.org/dist/v${PV}/node-v${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="dev-libs/openssl"
RDEPEND="${DEPEND}"

S=${WORKDIR}/node-v${PV}

src_prepare() {
	# fix compilation on Darwin
	# http://code.google.com/p/gyp/issues/detail?id=260
	sed -i -e "/append('-arch/d" tools/gyp/pylib/gyp/xcode_emulation.py || die
	python_convert_shebangs 2 tools/node-waf || die
}

src_configure() {
	./configure --prefix="${EPREFIX}"/usr --openssl-use-sys --shared-zlib || die
}

src_compile() {
	emake || die
}

src_install() {
	local MYLIB=$(get_libdir)
	mkdir -p "${ED}"/usr/include/node
	mkdir -p "${ED}"/usr/bin
	mkdir -p "${ED}"/usr/"${MYLIB}"/node_modules/npm
	mkdir -p "${ED}"/usr/"${MYLIB}"/node
	cp 'src/eio-emul.h' 'src/ev-emul.h' 'src/node.h' 'src/node_buffer.h' 'src/node_object_wrap.h' 'src/node_version.h' "${ED}"/usr/include/node || die "Failed to copy stuff"
	cp -R deps/uv/include/* "${ED}"/usr/include/node || die "Failed to copy stuff"
	cp -R deps/v8/include/* "${ED}"/usr/include/node || die "Failed to copy stuff"
	cp 'out/Release/node' "${ED}"/usr/bin/node || die "Failed to copy stuff"
	cp -R deps/npm/* "${ED}"/usr/"${MYLIB}"/node_modules/npm || die "Failed to copy stuff"
	cp -R tools/wafadmin "${ED}"/usr/"${MYLIB}"/node/ || die "Failed to copy stuff"
	cp 'tools/node-waf' "${ED}"/usr/bin/ || die "Failed to copy stuff"
	dosym /usr/"${MYLIB}"/node_modules/npm/bin/npm-cli.js /usr/bin/npm
	pax-mark -m "${ED}"/usr/bin/node
}

src_test() {
	emake test || die
}
