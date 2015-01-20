# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_ABI_TYPE="single"
PYTHON_DEPEND="monitor? ( <<>> )"
PYTHON_RESTRICTED_ABIS="3.* *-jython *-pypy"

inherit eutils linux-info linux-mod python

DESCRIPTION="Production quality, multilayer virtual switch."
HOMEPAGE="http://openvswitch.org"
SRC_URI="http://openvswitch.org/releases/${P}.tar.gz"

LICENSE="Apache-2.0 GPL-2"
SLOT="0"
KEYWORDS="~*"
IUSE="debug modules monitor +ssl"

RDEPEND=">=sys-apps/openrc-0.12.1
	ssl? ( dev-libs/openssl )
	monitor? ( $(python_abi_depend dev-python/twisted-core dev-python/twisted-web net-zope/zope.interface) )
	debug? ( dev-lang/perl )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

CONFIG_CHECK="~NET_CLS_ACT ~NET_CLS_U32 ~NET_SCH_INGRESS ~NET_ACT_POLICE ~IPV6 ~TUN"
MODULE_NAMES="openvswitch(net:${S}/datapath/linux)"
BUILD_TARGETS="all"

pkg_setup() {
	if use modules ; then
	        CONFIG_CHECK+=" ~!OPENVSWITCH"
			kernel_is ge 2 6 32 || die "Linux >=2.6.32 and <3.10 required"
			kernel_is lt 3 11 || die "Linux >=2.6.32 and <3.11 required"
		    linux-mod_pkg_setup
	else
		CONFIG_CHECK+=" ~OPENVSWITCH"
		linux-info_pkg_setup
	fi

	if use monitor; then python_pkg_setup; fi
}

src_prepare() {
	# Never build kernelmodules, doing this manually
	sed -i \
		-e '/^SUBDIRS/d' \
		datapath/Makefile.in || die "sed failed"
}

src_configure() {
	set_arch_to_kernel
	use monitor || export ovs_cv_python="no"

	local linux_config=()
	use modules && linux_config=("--with-linux=${KERNEL_DIR}")
	econf "${linux_config[@]}" \	
		--with-rundir=/var/run/openvswitch \
		--with-logdir=/var/log/openvswitch \
		--with-pkidir=/etc/ssl/openvswitch \
		--with-dbdir=/var/lib/openvswitch \
		$(use_enable ssl) \
		$(use_enable !debug ndebug)
}

src_compile() {
	default
	use modules && linux-mod_src_compile
}

src_install() {
	default
	if use monitor ; then
		insinto $(python_get_sitedir)
		doins -r "${ED}usr/share/openvswitch/python/"*
		rm -r "${ED}/usr/share/openvswitch/python"
		python_convert_shebangs -r "${PYTHON_ABI}" "${ED}"
	fi

	keepdir /var/{lib,log}/openvswitch
	keepdir /etc/ssl/openvswitch
	fperms 0750 /etc/ssl/openvswitch
	rm -rf "${ED}/var/run"

	newconfd "${FILESDIR}/openvswitch-2.0.0-ovsdb-server.conf" ovsdb-server
	newconfd "${FILESDIR}/ovs-vswitchd_conf" ovs-vswitchd
	newconfd "${FILESDIR}/ovs-controller_conf" ovs-controller
	newinitd "${FILESDIR}/ovsdb-server-r1" ovsdb-server
	newinitd "${FILESDIR}/ovs-vswitchd-r1" ovs-vswitchd
	newinitd "${FILESDIR}/ovs-controller-r1" ovs-controller
	insinto /etc/logrotate.d
	newins rhel/etc_logrotate.d_openvswitch openvswitch

	use modules && linux-mod_src_install
}

pkg_postinst() {
	use monitor && python_byte-compile_modules ovs ovstest
	use modules && linux-mod_pkg_postinst

	local pv
	for pv in ${REPLACING_VERSIONS}; do
		if ! version_is_at_least 1.9.0 ${pv} ; then
			ewarn "The configuration database for Open vSwitch got moved in version 1.9.0 from"
			ewarn "    /etc/openvswitch"
			ewarn "to"
			ewarn "    /var/lib/openvswitch"
			ewarn "Please copy/move the database manually before running the schema upgrade."
			ewarn "The PKI files are now supposed to go to /etc/ssl/openvswitch"
		fi
	done

	elog "${PN} built against kernels 3.11 and greater must have kernel built modules"
	elog "   instead of portage built kernel modules"
	elog "Use the following command to create an initial database for ovsdb-server:"
	elog "   emerge --config =${CATEGORY}/${PF}"
	elog "(will create a database in /var/lib/openvswitch/conf.db)"
	elog "or to convert the database to the current schema after upgrading."
}

pkg_config() {
	local db="${EPREFIX}/var/lib/openvswitch/conf.db"
	if [ -e "${db}" ] ; then
		einfo "Database '${db}' already exists, doing schema migration..."
		einfo "(if the migration fails, make sure that ovsdb-server is not running)"
		"${EPREFIX}/usr/bin/ovsdb-tool" convert "${db}" "${EPREFIX}/usr/share/openvswitch/vswitch.ovsschema" || die "converting database failed"
	else
		einfo "Creating new database '${db}'..."
		"${EPREFIX}/usr/bin/ovsdb-tool" create "${db}" "${EPREFIX}/usr/share/openvswitch/vswitch.ovsschema" || die "creating database failed"
	fi
}

pkg_postrm() {
	use monitor && python_clean_byte-compiled_modules ovs ovstest
}

