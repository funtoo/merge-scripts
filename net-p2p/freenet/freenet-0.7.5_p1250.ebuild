# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-p2p/freenet/freenet-0.7.5_p1250.ebuild,v 1.1 2010/06/13 15:20:58 tommy Exp $

EAPI="2"
DATE=20100425

inherit eutils java-pkg-2 java-ant-2 multilib

DESCRIPTION="An encrypted network without censorship"
HOMEPAGE="http://www.freenetproject.org/"
SRC_URI="http://github.com/${PN}/fred-official/zipball/build0${PV#*p} -> ${P}.zip
	mirror://gentoo/seednodes-${DATE}.fref"

LICENSE="as-is GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="freemail"

CDEPEND="dev-db/db-je:3.3
	dev-java/fec
	dev-java/java-service-wrapper
	dev-java/db4o-jdk11
	dev-java/db4o-jdk12
	dev-java/db4o-jdk5
	dev-java/ant-core
	dev-java/lzma
	dev-java/lzmajio
	dev-java/mersennetwister"
#force secure versions for now
DEPEND="app-arch/unzip
	>=virtual/jdk-1.5
	${CDEPEND}"
RDEPEND=">=virtual/jre-1.5
	net-libs/nativebiginteger
	${CDEPEND}"
PDEPEND="net-libs/NativeThread
	freemail? ( dev-java/bcprov )"

EANT_BUILD_TARGET="dist"
EANT_GENTOO_CLASSPATH="ant-core db4o-jdk5 db4o-jdk12 db4o-jdk11 db-je-3.3 fec java-service-wrapper lzma lzmajio mersennetwister"

pkg_setup() {
	has_version dev-java/icedtea[cacao] && {
		ewarn "dev-java/icedtea was built with cacao USE flag."
		ewarn "freenet may compile with it, but it will refuse to run."
		ewarn "Please remerge dev-java/icedtea without cacao USE flag,"
		ewarn "if you plan to use it for running freenet."
	}
	java-pkg-2_pkg_setup
	enewgroup freenet
	enewuser freenet -1 -1 /var/freenet freenet
}

src_prepare() {
	mv "${WORKDIR}"/freenet-fred-official-* "${S}"
	cd "${S}"
	cp "${FILESDIR}"/wrapper1.conf freenet-wrapper.conf || die
	cp "${FILESDIR}"/run.sh-20090501 run.sh || die
	epatch "${FILESDIR}"/ext.patch
	epatch "${FILESDIR}"/0.7.5_p1245-strip-openjdk-check.patch
	sed -i -e "s:=/usr/lib:=/usr/$(get_libdir):g" freenet-wrapper.conf || die "sed failed"
	use freemail && echo "wrapper.java.classpath.12=/usr/share/bcprov/lib/bcprov.jar" >> freenet-wrapper.conf
	java-ant_rewrite-classpath
	java-pkg-2_src_prepare
}

src_install() {
	java-pkg_newjar lib/freenet-cvs-snapshot.jar ${PN}.jar
	if has_version =sys-apps/baselayout-2*; then
		doinitd "${FILESDIR}"/freenet
	else
		newinitd "${FILESDIR}"/freenet.old freenet
	fi
	dodoc AUTHORS README || die
	insinto /etc
	doins freenet-wrapper.conf || die
	insinto /var/freenet
	doins run.sh || die
	newins "${DISTDIR}"/seednodes-${DATE}.fref seednodes.fref || die
	fperms +x /var/freenet/run.sh
	dosym java-service-wrapper/libwrapper.so /usr/$(get_libdir)/libwrapper.so
}

pkg_postinst () {
	elog " "
	elog "1. Start freenet with /etc/init.d/freenet start."
	elog "2. Open localhost:8888 in your browser for the web interface."
	#workaround for previously existing freenet user
	[[ $(stat --format="%U" /var/freenet) == "freenet" ]] || chown \
		freenet:freenet /var/freenet
}

pkg_postrm() {
	if ! [[ -e /usr/share/freenet/lib/freenet.jar ]] ; then
		elog " "
		elog "If you dont want to use freenet any more"
		elog "and dont want to keep your identity/other stuff"
		elog "remember to do 'rm -rf /var/freenet' to remove everything"
	fi
}
