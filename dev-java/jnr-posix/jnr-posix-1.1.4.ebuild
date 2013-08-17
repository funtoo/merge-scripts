# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/jnr-posix/jnr-posix-1.1.4.ebuild,v 1.5 2010/07/17 09:07:21 fauli Exp $

EAPI="2"
JAVA_PKG_IUSE="source test"
WANT_ANT_TASKS="ant-nodeps"

inherit java-pkg-2 java-ant-2

DESCRIPTION="Lightweight cross-platform POSIX emulation layer for Java"
HOMEPAGE="http://github.com/wmeissner/jnr-posix/"
SRC_URI="http://github.com/wmeissner/${PN}/tarball/${PV} -> ${P}.tar.gz"
LICENSE="|| ( CPL-1.0 GPL-2 LGPL-2.1 )"
SLOT="0"
KEYWORDS="amd64 x86 ~amd64-linux ~x86-linux ~x86-solaris"
IUSE=""

CDEPEND=">=dev-java/jaffl-0.5.1:0
	>=dev-java/constantine-0.7:0"

RDEPEND=">=virtual/jre-1.5
	${CDEPEND}"

DEPEND=">=virtual/jdk-1.5
	${CDEPEND}
	test? (
		dev-java/ant-junit4
		dev-java/jffi:0.4
	)"

src_unpack() {
	unpack ${A}
	mv w* "${P}" || die
}

java_prepare() {
	find . -iname '*.jar' -delete
	java-pkg_jar-from --into lib constantine
	java-pkg_jar-from --into lib jaffl

	sed -i -e 's_\.\./jaffl\.git/__g' nbproject/project.properties || die
}

EANT_EXTRA_ARGS="-Dreference.jaffl.jar=lib/jaffl.jar \
	-Dreference.constantine.jar=lib/constantine.jar \
	-Dproject.constantine=\"${S}\" \
	-Dproject.jaffl=\"${S}\" \
	-D\"already.built.${S}\"=true"

src_install() {
	java-pkg_dojar dist/${PN}.jar
	use source && java-pkg_dosrc src/*
	dodoc README.txt || die
}

src_test() {
	sed -i -e \
	"s_\${file.reference.jffi-complete.jar}_$(java-pkg_getjars --build-only --with-dependencies jffi-0.4,jaffl)_" \
		nbproject/project.properties

	ANT_TASKS="ant-junit4 ant-nodeps" eant test \
		-Dlibs.junit_4.classpath="$(java-pkg_getjars --with-dependencies junit-4)" \
		-Djava.library.path="$(java-config -di jaffl,constantine,jffi-0.4)" \
		${EANT_EXTRA_ARGS}
}
