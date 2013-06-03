# Distributed under the terms of the GNU General Public License v2

EAPI=4-python
PYTHON_DEPEND="<<2:2.7>>"

inherit eutils python

DESCRIPTION=""
HOMEPAGE="http://wiki.zenoss.org"
RESTRICT="mirror"
GITHUB_REPO="VirtualEnvBuild"
GITHUB_USER="zenoss"
GITHUB_TAG="1.2.10"
ZENOSS_A="zenoss-dev-20130125.tar.xz"
ZENOSS_PIP_A="zenoss-pip-distfiles-20130125.tar"
SRC_URI="http://www.github.com/${GITHUB_USER}/${GITHUB_REPO}/tarball/${GITHUB_TAG} -> zenoss-build-${GITHUB_TAG}.tar.gz http://www.funtoo.org/distfiles/zenoss/$ZENOSS_A http://www.funtoo.org/distfiles/zenoss/$ZENOSS_PIP_A"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

COMMON_DEPEND="
	=dev-lang/python-2.7*
	=dev-java/sun-jdk-1.6* 
	=dev-java/maven-bin-3* 
	=virtual/mysql-5.5* 
	>=net-analyzer/rrdtool-1.4.7[python] 
	net-nds/openldap[sasl] 
	net-analyzer/net-snmp 
	dev-python/pip 
	dev-python/virtualenv
	>=net-misc/rabbitmq-server-2.8.7
	dev-libs/libxslt[python]"
DEPEND="${COMMON_DEPEND} app-arch/unzip"
RDEPEND="${COMMON_DEPEND} net-misc/memcached"

pkg_setup() {
	enewgroup zenoss
	enewuser zenoss -1 /bin/bash /home/zenoss zenoss
	export GENTOO_VM=sun-jdk-1.6
}

src_unpack() {
	unpack zenoss-build-${GITHUB_TAG}.tar.gz
	mv "${WORKDIR}/$( cd $WORKDIR; ls )" "${S}" || die
	install -d ${S}/downloads
	cd ${S}/downloads; tar xvf ${DISTDIR}/${ZENOSS_PIP_A} || die "pip archive extract fail"
}

src_compile() {
	install -d ${S}/maven
	./build_zenoss.sh ${DISTDIR}/${ZENOSS_A} ${DISTDIR}/${ZENOSS_A} || die "build fail"
}

src_install() {
	mv ${S}/image/opt ${D}/opt || die "opt move fail"
}
