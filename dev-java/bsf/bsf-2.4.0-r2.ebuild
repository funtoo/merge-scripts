# Distributed under the terms of the GNU General Public License v2

EAPI="1"
JAVA_PKG_IUSE="doc examples source"
inherit java-pkg-2 eutils java-ant-2

DESCRIPTION="Bean Script Framework"
HOMEPAGE="http://commons.apache.org/bsf/"
SRC_URI="mirror://apache/jakarta/bsf/source/${PN}-src-${PV}.tar.gz"
LICENSE="Apache-2.0"
SLOT="2.3"
KEYWORDS="*"
# If you add new ones, add them to ant-apache-bsf too for use dependencies
IUSE="javascript python tcl"

COMMON_DEP="dev-java/commons-logging:0
	dev-java/xalan:0
	python? ( || ( dev-java/jython:2.2 dev-java/jython:2.1 ) )
	javascript? ( dev-java/rhino:1.6 )
	tcl? ( dev-java/jacl:0 )"
RDEPEND=">=virtual/jre-1.4
	${COMMON_DEP}"
DEPEND=">=virtual/jdk-1.4
	${COMMON_DEP}"

src_unpack() {
	unpack ${A}
	cd "${S}"

	rm -v lib/*.jar || die
	rm samples/*/*.class || die

	java-ant_ignore-system-classes
	java-ant_rewrite-classpath

	# somebody forgot to add them to source tarball... fetched from svn
	cp "${FILESDIR}/${P}-build-properties.xml" build-properties.xml || die
}

src_compile() {
	local pkgs="commons-logging,xalan"
	local antflags="-Dxalan.present=true"
	if use python; then
		local jython_version
		if has_version dev-java/jython:2.2 ; then
			jython_version="2.2"
		else
			jython_version="2.1"
		fi
		antflags="${antflags} -Djython.present=true"
		pkgs="${pkgs},jython-${jython_version}"
	fi
	if use javascript; then
		antflags="${antflags} -Drhino.present=true"
		pkgs="${pkgs},rhino-1.6"
	fi
	if use tcl; then
		antflags="${antflags} -Djacl.present=true"
		pkgs="${pkgs},jacl"
	fi

	local cp="$(java-pkg_getjars ${pkgs})"
	eant -Dgentoo.classpath="${cp}" ${antflags} jar
	# stupid clean
	mv build/lib/${PN}.jar "${S}" || die
	use doc && eant -Dgentoo.classpath="${cp}" ${antflags} javadocs
}

# does not have any, overwrite the one from java-pkg-2
src_test() {
	true;
}

src_install() {
	java-pkg_dojar ${PN}.jar

	java-pkg_dolauncher ${PN} --main org.apache.bsf.Main

	dodoc CHANGES.txt NOTICE.txt README.txt RELEASE-NOTE.txt TODO.txt || die

	use doc && java-pkg_dojavadoc build/javadocs
	use examples && java-pkg_doexamples samples
	use source && java-pkg_dosrc src/org

	java-pkg_register-optional-dependency bsh,groovy-1,jruby
}

pkg_postinst() {
	elog "Support for python, javascript, and tcl is controlled via USE flags."
	elog "Also, following languages can be supported just by installing"
	elog "respective package with USE=\"bsf\": BeanShell (dev-java/bsh),"
	elog "Groovy (dev-java/groovy) and JRuby (dev-java/jruby)"
}
