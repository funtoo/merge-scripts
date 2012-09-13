# Distributed under the terms of the GNU General Public License v2

EAPI="3"
PYTHON_DEPEND="python? 2"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.* *-jython"
PYTHON_MODNAME="netsnmp"
DISTUTILS_GLOBAL_OPTIONS=( "--basedir=${S}" )

inherit fixheadtails flag-o-matic perl-module python autotools distutils

DESCRIPTION="Software for generating and retrieving SNMP data"
HOMEPAGE="http://net-snmp.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="as-is BSD"
SLOT="0"
KEYWORDS="*"
IUSE="bzip2 diskio doc elf extensible ipv6 kernel_linux lm_sensors mfd-rewrites minimal perl python rpm selinux sendmail smux ssl tcpd X zlib"

COMMON="ssl? ( >=dev-libs/openssl-0.9.6d )
	tcpd? ( >=sys-apps/tcp-wrappers-7.6 )
	rpm? (
		app-arch/rpm
		dev-libs/popt
		app-arch/bzip2
		>=sys-libs/zlib-1.1.4
	)
	bzip2? ( app-arch/bzip2 )
	zlib? ( >=sys-libs/zlib-1.1.4 )
	elf? ( dev-libs/elfutils )
	lm_sensors? (
		kernel_linux? ( sys-apps/lm_sensors )
	)
	python? ( dev-python/setuptools )"

RDEPEND="${COMMON}
	perl? (
		X? ( dev-perl/perl-tk )
		!minimal? ( dev-perl/TermReadKey )
	)
	selinux? ( sec-policy/selinux-snmpd )"

# Dependency on autoconf due to bug #225893
DEPEND="${COMMON}
	>=sys-devel/autoconf-2.61-r2
	>=sys-apps/sed-4
	doc? ( app-doc/doxygen )"

pkg_setup() {
	use python && python_pkg_setup
}

src_prepare() {
	# lm_sensors-3 support
	if use lm_sensors ; then
		epatch "${FILESDIR}"/${PN}-5.4.1-sensors3.patch \
			"${FILESDIR}"/${PN}-5.4.1-sensors3-version_detect.patch
	fi

	# fix access violation in make check
	sed -i -e 's/\(snmpd.*\)-Lf/\1-l/' testing/eval_tools.sh || \
		die "sed eval_tools.sh failed"
	# fix path in fixproc
	sed -i -e 's|\(database_file =.*\)/local\(.*\)$|\1\2|' local/fixproc || \
		die "sed fixproc failed"

	if use python ; then
		sed -i -e "s:\(install --basedir=\$\$dir\):\1 --root='${D}':" Makefile.in || \
			die "sed python failed"
	fi

	# snmpconf generates config files with proper selinux context
	use selinux && epatch "${FILESDIR}"/${PN}-5.1.2-snmpconf-selinux.patch

	# remove CFLAGS from net-snmp-config script (bug #257622):
	sed -i -e 's|@CFLAGS@||g' -e 's|@LDFLAGS@||g' \
		net-snmp-config.in || die "sedding CFLAGS/LDFLAGS failed"

	# Respect LDFLAGS
	sed -i Makefile.top \
		-e '/^LIB_LD_CMD/{s|$(CFLAGS)|& $(LDFLAGS)|g}' \
		|| die "sed LDFLAGS failed"

	# Fix version number:
	sed -i -e "s:NetSnmpVersionInfo = \".*\":NetSnmpVersionInfo = \"${PV}\":" \
		snmplib/snmp_version.c || die "sedding version failed"

	eautoreconf

	ht_fix_all
}

src_configure() {
	strip-flags

	local mibs="host ucd-snmp/dlmod"
	use diskio && mibs="${mibs} ucd-snmp/diskio"
	use extensible && mibs="${mibs} ucd-snmp/extensible"
	use lm_sensors && mibs="${mibs} ucd-snmp/lmsensorsMib"
	use sendmail && mibs="${mibs} mibII/mta_sendmail"
	use smux && mibs="${mibs} smux"

	# We use --without-python below because distutils takes care of building
	# python directly.

	local myconf="$(use_enable ipv6) \
			$(use_enable mfd-rewrites) \
			$(use_enable perl embedded-perl) \
			$(use_enable !ssl internal-md5) \
			$(use_with elf) \
			$(use_with perl perl-modules INSTALLDIRS=vendor ) \
			--without-python \
			$(use_with ssl openssl) \
			$(use_with tcpd libwrap)"
	if use rpm ; then
		myconf="${myconf} \
			--with-rpm \
			--with-bzip2 \
			--with-zlib"
	else
		myconf="${myconf} \
			--without-rpm \
			$(use_with bzip2) \
			$(use_with zlib)"
	fi

	econf \
		--with-install-prefix="${D}" \
		--with-sys-location="Unknown" \
		--with-sys-contact="root@Unknown" \
		--with-default-snmp-version="3" \
		--with-mib-modules="${mibs}" \
		--with-logfile="/var/log/net-snmpd.log" \
		--with-persistent-directory="/var/lib/net-snmp" \
		--enable-ucd-snmp-compatibility \
		--enable-shared \
		--with-ldflags="${LDFLAGS}" \
		--enable-as-needed \
		${myconf}
}

src_compile() {
	emake -j1 OTHERLDFLAGS="${LDFLAGS}" || die "emake failed"

	if use python; then
		cd python
		distutils_src_compile
		cd ..
	fi

	if use doc ; then
		einfo "Building HTML Documentation"
		make docsdox || die "failed to build docs"
	fi
}

src_test() {
	cd testing
	if ! make test ; then
		echo
		einfo "Don't be alarmed if a few tests FAIL."
		einfo "This could happen for several reasons:"
		einfo "    - You don't already have a working configuration."
		einfo "    - Your ethernet interface isn't properly configured."
		echo
	fi
}

src_install () {
	# bug #317965
	emake -j1 DESTDIR="${D}" install || die "make install failed"

	if use python; then
		cd python
		distutils_src_install
		cd ..
	fi

	if use perl ; then
		fixlocalpod
		use X || rm -f "${D}"/usr/bin/tkmib
	else
		rm -f "${D}"/usr/bin/mib2c "${D}"/usr/bin/snmpcheck "${D}"/usr/bin/tkmib
	fi

	dodoc AGENT.txt ChangeLog FAQ INSTALL NEWS PORTING README* TODO || die
	newdoc EXAMPLE.conf.def EXAMPLE.conf || die

	use doc && { dohtml docs/html/* || die ; }

	keepdir /etc/snmp /var/lib/net-snmp

	newinitd "${FILESDIR}"/$PVR/snmpd.init snmpd || die
	newconfd "${FILESDIR}"/$PVR/snmpd.conf.d snmpd || die

	newinitd "${FILESDIR}"/$PVR/snmptrapd.init snmptrapd || die
	newconfd "${FILESDIR}"/$PVR/snmptrapd.conf.d snmptrapd || die

	# Remove everything not required for an agent.
	# Keep only the snmpd, snmptrapd, MIBs, headers and libraries.
	if use minimal; then
		elog "USE='minimal' is set. Removing excess/non-minimal components."
		rm -rf
		"${D}"/usr/bin/{encode_keychange,snmp{get,getnext,set,usm,walk,bulkwalk,table,trap,bulkget,translate,status,delta,test,df,vacm,netstat,inform,snmpcheck}}
		rm -rf "${D}"/usr/share/snmp/snmpconf-data "${D}"/usr/share/snmp/*.conf
		rm -rf "${D}"/usr/bin/{fixproc,traptoemail} "${D}"/usr/bin/snmpc{heck,onf}
		find "${D}" -name '*.pl' -exec rm -f '{}' \;
		use ipv6 || rm -rf "${D}"/usr/share/snmp/mibs/IPV6*
	fi

	# bug 113788, install example config
	insinto /etc/snmp
	newins "${S}"/EXAMPLE.conf snmpd.conf.example || die
	insinto /usr/share/snmp
	newins ${FILESDIR}/$PVR/snmpd.conf snmpd.conf.basic || die
}

pkg_postinst() {
	if ! [ -e ${ROOT}/etc/snmp/snmpd.conf ]; then
		cp $ROOT/usr/share/snmp/snmpd.conf.basic ${ROOT}/etc/snmp/snmpd.conf
		elog "A basic working snmpd configuration file has been installed to /etc/snmpd/snmpd.conf."
	fi

	if use python; then
		distutils_pkg_postinst
	fi
}

pkg_postrm() {
	if use python; then
		distutils_pkg_postrm
	fi
}
