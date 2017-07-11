# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="100% pure-Java implementation of the Ruby programming language"
HOMEPAGE="http://www.jruby.org/"
SRC_URI="http://jruby.org.s3.amazonaws.com/downloads/${PV}/${P}.tar.gz"

LICENSE="EPL GPL2 LGPL2.1 custom"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}
	app-shells/bash
	>=virtual/jre-1.8
"
src_install() {
	dodir /opt/${PN}
	mv ${WORKDIR}/* ${ED}/opt/${PN}
	find ${ED}/opt/${PN}/${P} -regextype posix-extended -regex '.*\.(bat|dll|exe)' -delete
	rm -r ${ED}/opt/${PN}/${P}/lib/jni/{Darwin,*-SunOS,*-Windows,*-AIX,*-*BSD} || die "rm failed"
	rm -r ${ED}/opt/${PN}/${P}/lib/ruby/stdlib/ffi/platform/{*-darwin,*-solaris,*-windows,*-aix,*-*bsd,*-cygwin} || die "rm failed"

	for f in jruby{,c} jirb{,_swing} jgem; do
		dosym /opt/${PN}/${P}/bin/${f} /usr/bin/${f}
	done
}
