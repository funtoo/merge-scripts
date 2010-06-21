# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-p2p/freenet/freenet-9999.ebuild,v 1.9 2010/05/05 16:14:38 tommy Exp $

EAPI="1"
DATE=20091027

EGIT_REPO_URI="git://github.com/freenet/fred-official.git"
EGIT_PROJECT="freenet/fred-official"

inherit eutils git java-pkg-2 java-ant-2 multilib

DESCRIPTION="An encrypted network without censorship"
HOMEPAGE="http://www.freenetproject.org/"
SRC_URI="mirror://gentoo/seednodes-${DATE}.fref"

LICENSE="as-is GPL-2"
SLOT="0"
KEYWORDS=""
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
DEPEND=">=virtual/jdk-1.5
	${CDEPEND}"
RDEPEND=">=virtual/jre-1.5
	net-libs/nativebiginteger
	${CDEPEND}"
PDEPEND="net-libs/NativeThread
	freemail? ( dev-java/bcprov )"
S=${WORKDIR}/${PN}

EANT_BUILD_TARGET="dist"
EANT_GENTOO_CLASSPATH="ant-core db4o-jdk5 db4o-jdk12 db4o-jdk11 db-je-3.3 fec java-service-wrapper lzma lzmajio mersennetwister"

pkg_setup() {
	java-pkg-2_pkg_setup
	enewgroup freenet
	enewuser freenet -1 -1 /var/freenet freenet
}

src_unpack() {
	git_src_unpack
	cd "${S}"
	cp "${FILESDIR}"/wrapper1.conf freenet-wrapper.conf || die
	cp "${FILESDIR}"/run.sh-20090501 run.sh || die
	epatch "${FILESDIR}"/ext.patch
	sed -i -e "s:=/usr/lib:=/usr/$(get_libdir):g" freenet-wrapper.conf || die "sed failed"
	use freemail && echo "wrapper.java.classpath.12=/usr/share/bcprov/lib/bcprov.jar" >> freenet-wrapper.conf
	java-ant_rewrite-classpath
	cp "${DISTDIR}"/seednodes-${DATE}.fref seednodes.fref || die
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
	doins seednodes.fref run.sh || die
	fperms +x /var/freenet/run.sh
	dosym java-service-wrapper/libwrapper.so /usr/$(get_libdir)/libwrapper.so
}

pkg_postinst() {
	elog
	elog "1. Start freenet with /etc/init.d/freenet start."
	elog "2. Open localhost:8888 in your browser for the web interface."
	#workaround for previously existing freenet user
	[[ $(stat --format="%U" /var/freenet) == "freenet" ]] || chown \
		freenet:freenet /var/freenet
}

pkg_postrm() {
	if ! [[ -e /usr/share/freenet/lib/freenet.jar ]] ; then
		elog "If you dont want to use freenet any more"
		elog "and dont want to keep your identity/other stuff"
		elog "remember to do 'rm -rf /var/freenet' to remove everything"
	fi
}
