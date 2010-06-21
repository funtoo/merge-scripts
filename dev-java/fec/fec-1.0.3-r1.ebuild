# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/fec/fec-1.0.3-r1.ebuild,v 1.4 2009/03/09 22:34:52 maekke Exp $

JAVA_PKG_IUSE="doc source"

inherit flag-o-matic java-pkg-2 java-ant-2 toolchain-funcs

DESCRIPTION="Forword error correction libs"
HOMEPAGE="http://www.onionnetworks.com/developers/"
SRC_URI="http://www.onionnetworks.com/downloads/${P}.zip"

LICENSE="as-is"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

COMMON_DEPEND="dev-java/log4j
	dev-java/concurrent-util
	!net-libs/fec"

RDEPEND=">=virtual/jre-1.4
	${COMMON_DEPEND}"
DEPEND=">=virtual/jdk-1.4
	app-arch/unzip
	${COMMON_DEPEND}"
EANT_BUILD_TARGET="jars"

src_unpack() {
	unpack ${A}
	cd "${S}" || die
	sed -i -e 's/build.compiler=jikes/#build.compiler=jikes/g' build.properties || die
	epatch "${FILESDIR}"/libfec8path.patch
	eant clean
	cd lib || die
	rm -v *.jar || die
	java-pkg_jar-from log4j
	java-pkg_jar-from concurrent-util concurrent.jar concurrent-jaxed.jar
	cd "${S}" || die
	unzip -q common-20020926.zip || die
	cd common-20020926 || die
	eant clean
	cp -r src/com ../src/ || die
}

src_compile() {
	java-pkg-2_src_compile
	if use x86; then
		cd "${S}"/src/csrc
		use hardened && append-flags -fPIC
		emake CC=$(tc-getCC) CFLAGS="${CFLAGS}" || die
	fi
}

src_install() {
	java-pkg_newjar lib/onion-${PN}.jar ${PN}.jar
	use doc && java-pkg_dojavadoc javadoc
	use source && java-pkg_dosrc src/com
	if use x86; then
		 dolib.so lib/fec-linux-x86/lib/linux/x86/libfec{8,16}.so || die
	fi
}
