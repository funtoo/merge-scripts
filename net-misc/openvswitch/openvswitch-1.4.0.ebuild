# Distributed under the terms of the GNU General Public License v2

EAPI=4

PYTHON_DEPEND="monitor? 2"

inherit linux-mod linux-info python

DESCRIPTION="Production quality, multilayer virtual switch."
HOMEPAGE="http://openvswitch.org"
SRC_URI="http://openvswitch.org/releases/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="debug modules monitor +pyside +ssl"

RDEPEND="ssl? ( dev-libs/openssl )
	monitor? ( dev-python/twisted
		dev-python/twisted-conch
		pyside? ( dev-python/pyside )
		!pyside? ( dev-python/PyQt4 )
		net-zope/zope-interface )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

CONFIG_CHECK="~NET_CLS_ACT ~NET_CLS_U32 ~NET_SCH_INGRESS ~NET_ACT_POLICE ~IPV6 ~TUN"

pkg_setup() {
	linux-mod_pkg_setup
	linux_chkconfig_module BRIDGE || die "CONFIG_BRIDGE must be built as a _module_ !"
}

src_configure() {
	set_arch_to_kernel
	if use modules; then
		modulebuild=$(use_with modules linux "${KERNEL_DIR}")
	else
		modulebuild=""
	fi
	use monitor || export ovs_cv_python="no"
	use pyside || export ovs_cv_pyuic4="no"
	econf \
		--with-rundir=/var/run/openvswitch \
		--with-logdir=/var/log/openvswitch \
		--with-pkidir=/etc/openvswitch/pki \
		$(use_enable ssl) \
		$(use_enable !debug ndebug) \
		${modulebuild} 
}

src_compile() {
	default
}

src_install() {
	default
	
	if use modules; then
	MODULE_NAMES="openvswitch_mod(misc:${S}:datapath/linux/) brcompat_mod(misc:${S}:datapath/linux/)"
	linux-mod_src_install
	fi

	keepdir /var/log/openvswitch
	keepdir /etc/openvswitch/pki
	rm -rf "${D}/var/run"
	rmdir "${D}/usr/share/openvswitch/ovsdbmonitor"

	newconfd "${FILESDIR}/ovsdb-server_conf" ovsdb-server
	newconfd "${FILESDIR}/ovs-vswitchd_conf" ovs-vswitchd
	doinitd "${FILESDIR}/ovsdb-server"
	doinitd "${FILESDIR}/ovs-vswitchd"
}
