# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/gcj-jdk/gcj-jdk-4.5.2-r1.ebuild,v 1.1 2011/09/20 15:37:19 caster Exp $

EAPI="2"

inherit java-vm-2 toolchain-funcs multilib versionator

DESCRIPTION="Java wrappers around GCJ"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI=""

LICENSE="GPL-2"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
SLOT="0"
IUSE=""

ECJ_GCJ_SLOT="3.5"

RDEPEND="~sys-devel/gcc-${PV}[gcj]
	dev-java/ecj-gcj:${ECJ_GCJ_SLOT}"
DEPEND="${RDEPEND}"

JAVA_PROVIDE="jdbc-stdext jdbc2-stdext gnu-jaxp"

pkg_setup() {
	if [[ $(gcc-fullversion) != ${PV} ]]; then
		eerror "Your current GCC version is not set to ${PV} via gcc-config"
		eerror "Please read http://www.gentoo.org/doc/en/gcc-upgrading.xml before you set it"
		echo "$(gcc-fullversion) != ${PV}"
		die "gcc ${PV} must be selected via gcc-config"
	fi

	java-vm-2_pkg_setup
}

src_install() {
	# jre lib paths ...
	local libarch="$(get_system_arch)"
	local gccbin=$(gcc-config -B)
	local gcclib=$(gcc-config -L|cut -d':' -f1)
	local gcjhome="/usr/lib/${P}"
	local gcc_version=$(gcc-fullversion)
	local gccchost="${CHOST}"

	# correctly install gcj
	dosym ${gccbin}/gij /usr/bin/gij
	dosym ${gccbin}/gcj-dbtool /usr/bin/gcj-dbtool

	# links
	dodir ${gcjhome}/bin
	dodir ${gcjhome}/jre/bin
	dosym ${gcjhome}/bin/java ${gcjhome}/jre/bin/java
	dosym ${gccbin}/gjar ${gcjhome}/bin/jar
	dosym ${gccbin}/gjdoc ${gcjhome}/bin/javadoc
	dosym ${gccbin}/grmic ${gcjhome}/bin/rmic
	dosym ${gccbin}/gjavah ${gcjhome}/bin/javah
	dosym ${gccbin}/jcf-dump ${gcjhome}/bin/javap
	dosym ${gccbin}/gappletviewer ${gcjhome}/bin/appletviewer
	dosym ${gccbin}/gjarsigner ${gcjhome}/bin/jarsigner
	dosym ${gccbin}/grmiregistry ${gcjhome}/bin/rmiregistry
	dosym ${gccbin}/grmiregistry ${gcjhome}/jre/bin/rmiregistry
	dosym ${gccbin}/gkeytool ${gcjhome}/bin/keytool
	dosym ${gccbin}/gkeytool ${gcjhome}/jre/bin/keytool
	dosym ${gccbin}/gnative2ascii ${gcjhome}/bin/native2ascii
	dosym ${gccbin}/gorbd ${gcjhome}/bin/orbd
	dosym ${gccbin}/gorbd ${gcjhome}/jre/bin/orbd
	dosym ${gccbin}/grmid ${gcjhome}/bin/rmid
	dosym ${gccbin}/grmid ${gcjhome}/jre/bin/rmid
	dosym ${gccbin}/gserialver ${gcjhome}/bin/serialver
	dosym ${gccbin}/gtnameserv ${gcjhome}/bin/tnameserv
	dosym ${gccbin}/gtnameserv ${gcjhome}/jre/bin/tnameserv
	dodir ${gcjhome}/jre/lib/${libarch}/client
	dosym /usr/$(get_libdir)/gcj-${gcc_version}*/libjvm.so ${gcjhome}/jre/lib/${libarch}/client/libjvm.so
	dosym /usr/$(get_libdir)/gcj-${gcc_version}*/libjvm.so ${gcjhome}/jre/lib/${libarch}/server/libjvm.so
	dosym /usr/$(get_libdir)/gcj-${gcc_version}*/libjawt.so ${gcjhome}/jre/lib/${libarch}/libjawt.so
	dosym /usr/share/gcc-data/${gccchost}/${gcc_version}/java/libgcj-${gcc_version/_/-}.jar \
		${gcjhome}/jre/lib/rt.jar
	dodir ${gcjhome}/lib
	dosym /usr/share/gcc-data/${gccchost}/${gcc_version}/java/libgcj-tools-${gcc_version/_/-}.jar \
		${gcjhome}/lib/tools.jar
	dosym ${gcclib}/include ${gcjhome}

	dosym /usr/bin/ecj-gcj-${ECJ_GCJ_SLOT} ${gcjhome}/bin/javac;
	dosym /usr/bin/gij ${gcjhome}/bin/java;

	set_java_env
}

pkg_postinst() {

	# Do not set as system VM (see below)
	# java-vm-2_pkg_postinst

	ewarn "gcj does not currently provide all the 1.5 APIs."
	ewarn "See http://builder.classpath.org/japi/libgcj-jdk15.html"
	ewarn "Check for existing bugs relating to missing APIs and file"
	ewarn "new ones at http://gcc.gnu.org/bugzilla/"
	ewarn
	ewarn "Due to this and limited manpower, we currently cannot support"
	ewarn "using gcj-jdk as a system VM. Its main purpose is to bootstrap"
	ewarn "IcedTea without prior binary VM installation. To do that, execute:"
	ewarn
	ewarn "emerge -o icedtea && emerge icedtea"

}
