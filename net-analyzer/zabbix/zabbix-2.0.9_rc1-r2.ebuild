# Distributed under the terms of the GNU General Public License v2

EAPI="5"

# needed to make webapp-config dep optional
WEBAPP_OPTIONAL="yes"
inherit flag-o-matic webapp depend.php autotools java-pkg-opt-2 user toolchain-funcs

DESCRIPTION="ZABBIX is software for monitoring of your applications, network and servers."
HOMEPAGE="http://www.zabbix.com/"
MY_P=${P/_/}
MY_PV=${PV/_/}
SRC_URI="http://prdownloads.sourceforge.net/zabbix/${MY_P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
WEBAPP_MANUAL_SLOT="yes"
KEYWORDS="~*"
IUSE="agent java curl frontend ipv6 jabber ldap mysql openipmi oracle postgres proxy server ssh snmp sqlite iodbc odbc static"

COMMON_DEPEND="snmp? ( net-analyzer/net-snmp )
	ldap? (
		net-nds/openldap
		=dev-libs/cyrus-sasl-2*
		net-libs/gnutls
	)
	mysql? ( >=virtual/mysql-5.0 )
	sqlite? ( >=dev-db/sqlite-3.3.5 )
	postgres? ( >=dev-db/postgresql-base-8.3.0 )
	oracle? ( >=dev-db/oracle-instantclient-basic-10.0.0.0 )
	jabber? ( dev-libs/iksemel )
	curl? ( net-misc/curl )
	openipmi? ( sys-libs/openipmi )
	ssh? ( net-libs/libssh2 )
	java? ( >=virtual/jdk-1.4 )
	odbc? (
		iodbc? ( dev-db/libiodbc )
		!iodbc? ( dev-db/unixODBC )
	)"

RDEPEND="${COMMON_DEPEND}
	proxy? ( <=net-analyzer/fping-2.9 )
	server? ( <=net-analyzer/fping-2.9
		app-admin/webapp-config )
	java?	(
		>=virtual/jre-1.4
		dev-java/slf4j-api
		dev-java/json-simple
	)
	frontend? (
		dev-lang/php[bcmath,ctype,sockets,gd,truetype,xml,session,xmlreader,xmlwriter,nls,sysvipc,unicode]
		|| ( dev-lang/php[apache2] dev-lang/php[cgi] dev-lang/php[fpm] )
		media-libs/gd[png]
		app-admin/webapp-config )"
DEPEND="${COMMON_DEPEND}
	virtual/pkgconfig"

S=${WORKDIR}/${MY_P}

ZABBIXJAVA_BASE="opt/zabbix_java"

java_prepare() {
	cd "${S}/src/zabbix_java/lib"
	rm -v *.jar || die

	java-pkg_jar-from slf4j-api
	java-pkg_jar-from json-simple
}

src_prepare() {
	epatch "${FILESDIR}/2.0/patches/zbx282.patch"
	eautoreconf
}

pkg_setup() {
	if use server || use proxy ; then
		local dbnum dbtypes="mysql oracle postgres sqlite" dbtype
		declare -i dbnum=0
		for dbtype in ${dbtypes}; do
			use ${dbtype} && let dbnum++
		done
		if [ ${dbnum} -gt 1 ]; then
			eerror
			eerror "You can't use more than one database type in Zabbix."
			eerror "Select exactly one database type out of these: ${dbtypes}"
			eerror
			die "Multiple database types selected."
		elif [ ${dbnum} -lt 1 ]; then
			eerror
			eerror "Select exactly one database type out of these: ${dbtypes}"
			eerror
			die "No database type selected."
		fi
		if use oracle; then
			if [ -z "${ORACLE_HOME}" ]; then
				eerror
				eerror "The environment variable ORACLE_HOME must be set"
				eerror "and point to the correct location."
				eerror "It looks like you don't have Oracle installed."
				eerror
				die "Environment variable ORACLE_HOME is not set"
			fi
			if has_version 'dev-db/oracle-instantclient-basic'; then
				ewarn
				ewarn "Please ensure you have a full install of the Oracle client."
				ewarn "dev-db/oracle-instantclient* is NOT sufficient."
				ewarn
			fi
		fi
	fi

	if use frontend; then
		webapp_pkg_setup
	fi

	enewgroup zabbix
	enewuser zabbix -1 -1 /var/lib/zabbix/home zabbix
}

pkg_postinst() {
	if use server || use proxy ; then
		elog
		elog "You may need to configure your database for Zabbix,"
		elog "if you have not already done so.  Most minor version"
		elog "zabbix updates do not require db changes. However, "
		elog "you should read the release notes to be sure."
		elog
		elog "Have a look at /usr/share/zabbix for"
		elog "database creation and upgrades."
		elog
		elog "Execute schema, images, and data sql files in that order."
		elog
		elog "For more info read the Zabbix manual at"
		elog "http://www.zabbix.com/documentation.php"
		elog
		elog "New use flags: java, odbc, iodbc"
		elog

		zabbix_homedir=$(egethome zabbix)
		if [ -n "${zabbix_homedir}" ] && \
		   [ "${zabbix_homedir}" != "/var/lib/zabbix/home" ]; then
			ewarn
			ewarn "The user 'zabbix' should have his homedir changed"
			ewarn "to /var/lib/zabbix/home if you want to use"
			ewarn "custom alert scripts."
			ewarn
			ewarn "A real homedir might be needed for configfiles"
			ewarn "for custom alert scripts (e.g. ~/.sendxmpprc when"
			ewarn "using sendxmpp for Jabber alerts)."
			ewarn
			ewarn "To change the homedir use:"
			ewarn "  usermod -d /var/lib/zabbix/home zabbix"
			ewarn
		fi
	fi

	if use server; then
		elog
		elog "For distributed monitoring you have to run:"
		elog
		elog "zabbix_server -n <nodeid>"
		elog
		elog "This will convert database data for use with Node ID"
		elog "and also adds a local node."
		elog
	fi

	elog "--"
	elog
	elog "You may need to add these lines to /etc/services:"
	elog
	elog "zabbix-agent     10050/tcp Zabbix Agent"
	elog "zabbix-agent     10050/udp Zabbix Agent"
	elog "zabbix-trapper   10051/tcp Zabbix Trapper"
	elog "zabbix-trapper   10051/udp Zabbix Trapper"
	elog

	elog "Feel free to download or contribute gentoo specific zabbix templates"
	elog "via https://github.com/deploylinux/gentooZabbixTemplates (WIP)."

	# repeat fowners/fperms functionality from src_install()
	# here to catch wrong permissions on existing files in
	# the live filesystem (yeah, that sucks).
	chown -R zabbix:zabbix \
		"${ROOT}"/etc/zabbix \
		"${ROOT}"/var/lib/zabbix \
		"${ROOT}"/var/lib/zabbix/home \
		"${ROOT}"/var/lib/zabbix/scripts \
		"${ROOT}"/var/log/zabbix
	chmod 0750 \
		"${ROOT}"/etc/zabbix \
		"${ROOT}"/var/lib/zabbix \
		"${ROOT}"/var/lib/zabbix/home \
		"${ROOT}"/var/lib/zabbix/scripts \
		"${ROOT}"/var/log/zabbix

	chmod 0640 \
		"${ROOT}"/etc/zabbix/zabbix_*

	if use server || use proxy ; then
		# check for fping
		fping_perms=$(stat -c %a /usr/sbin/fping 2>/dev/null)
		case "${fping_perms}" in
			4[157][157][157])
				;;
			*)
				ewarn
				ewarn "If you want to use the checks 'icmpping' and 'icmppingsec',"
				ewarn "you have to make /usr/sbin/fping setuid root and executable"
				ewarn "by everyone. Run the following command to fix it:"
				ewarn
				ewarn "  chmod u=rwsx,g=rx,o=rx /usr/sbin/fping"
				ewarn
				ewarn "Please be aware that this might impose a security risk,"
				ewarn "depending on the code quality of fping."
				ewarn
				ebeep 3
				epause 5
				;;
		esac
	fi
}

src_configure() {

	local myconf

	if use odbc && use iodbc ; then
	   myconf="${myconf} --with-iodbc --without-unixodbc"
	elif use odbc && ! use iodbc; then
	   myconf="${myconf} --with-unixodbc --without-iodbc"
	else
	   myconf="${myconf} --without-unixodbc --without-iodbc"
	fi

	econf \
		$myconf \
		$(use_enable server) \
		$(use_enable proxy) \
		$(use_enable agent) \
		$(use_enable ipv6) \
		$(use_enable static) \
		$(use_enable java) \
		$(use_with ldap) \
		$(use_with snmp net-snmp) \
		$(use_with mysql) \
		$(use_with postgres postgresql) \
		$(use_with oracle) \
		$(use_with sqlite sqlite3) \
		$(use_with jabber) \
		$(use_with curl libcurl) \
		$(use_with openipmi openipmi) \
		$(use_with ssh ssh2) \
		|| die "econf failed"
}

src_install() {
	dodir \
		/etc/zabbix \
		/var/lib/zabbix \
		/var/lib/zabbix/home \
		/var/lib/zabbix/scripts \
		/var/log/zabbix

	keepdir \
		/etc/zabbix \
		/var/lib/zabbix \
		/var/lib/zabbix/home \
		/var/lib/zabbix/scripts \
		/var/log/zabbix

	if use server; then
		insinto /etc/zabbix
		doins \
			"${FILESDIR}/1.6.6"/zabbix_server.conf \
			"${FILESDIR}/1.6.6"/zabbix_trapper.conf
		doinitd \
			"${FILESDIR}/2.0"/init.d/zabbix-server
		dosbin \
			src/zabbix_server/zabbix_server
		dodir \
			/usr/share/zabbix
		insinto /usr/share/zabbix
		doins -r \
			database \
			upgrades
		fowners zabbix:zabbix \
			/etc/zabbix/zabbix_server.conf \
			/etc/zabbix/zabbix_trapper.conf
		fperms 0640 \
			/etc/zabbix/zabbix_server.conf \
			/etc/zabbix/zabbix_trapper.conf
	fi

	if use proxy; then
		doinitd \
			"${FILESDIR}/2.0"/init.d/zabbix-proxy
		dosbin \
			src/zabbix_proxy/zabbix_proxy
		insinto /etc/zabbix
		doins \
			"${FILESDIR}/2.0"/zabbix_proxy.conf
		dodir \
			/usr/share/zabbix
		insinto /usr/share/zabbix
		doins -r \
			database
	fi

	if use agent; then
		insinto /etc/zabbix
		doins \
			"${FILESDIR}/1.6.6"/zabbix_agent.conf \
			"${FILESDIR}/1.6.6"/zabbix_agentd.conf
		doinitd \
			"${FILESDIR}/2.0"/init.d/zabbix-agentd
		dosbin \
			src/zabbix_agent/zabbix_agent \
			src/zabbix_agent/zabbix_agentd
		dobin \
			src/zabbix_sender/zabbix_sender \
			src/zabbix_get/zabbix_get
		fowners zabbix:zabbix \
			/etc/zabbix/zabbix_agent.conf \
			/etc/zabbix/zabbix_agentd.conf
		fperms 0640 \
			/etc/zabbix/zabbix_agent.conf \
			/etc/zabbix/zabbix_agentd.conf
	fi

	fowners zabbix:zabbix \
		/etc/zabbix \
		/var/lib/zabbix \
		/var/lib/zabbix/home \
		/var/lib/zabbix/scripts \
		/var/log/zabbix
	fperms 0750 \
		/etc/zabbix \
		/var/lib/zabbix \
		/var/lib/zabbix/home \
		/var/lib/zabbix/scripts \
		/var/log/zabbix

	dodoc README INSTALL NEWS ChangeLog \
		conf/zabbix_agent.conf \
		conf/zabbix_agentd.conf \
		conf/zabbix_proxy.conf \
		conf/zabbix_agentd/userparameter_examples.conf \
		conf/zabbix_agentd/userparameter_mysql.conf \
		conf/zabbix_server.conf

	if use frontend; then
		webapp_src_preinst
		cp -R frontends/php/* "${D}/${MY_HTDOCSDIR}"
		webapp_postinst_txt en "${FILESDIR}/"1.6.6/postinstall-en.txt
		webapp_configfile \
			"${MY_HTDOCSDIR}"/include/db.inc.php \
			"${MY_HTDOCSDIR}"/include/config.inc.php
		webapp_src_install
	fi

	if use java; then
	   dodir \
	   	/${ZABBIXJAVA_BASE} \
		/${ZABBIXJAVA_BASE}/bin \
		/${ZABBIXJAVA_BASE}/lib
	   keepdir /${ZABBIXJAVA_BASE}
	   exeinto /${ZABBIXJAVA_BASE}/bin
	   doexe src/zabbix_java/bin/zabbix-java-gateway-${MY_PV}.jar
	   exeinto /${ZABBIXJAVA_BASE}/lib
	   doexe \
	   	src/zabbix_java/lib/logback-classic-0.9.27.jar \
		src/zabbix_java/lib/logback-console.xml \
		src/zabbix_java/lib/logback-core-0.9.27.jar \
		src/zabbix_java/lib/logback.xml \
		src/zabbix_java/lib/org-json-2010-12-28.jar \
		src/zabbix_java/lib/slf4j-api-1.6.1.jar
	   exeinto /${ZABBIXJAVA_BASE}/
	   doexe \
	   	src/zabbix_java/settings.sh \
		src/zabbix_java/startup.sh \
		src/zabbix_java/shutdown.sh
	   fowners -R zabbix:zabbix /${ZABBIXJAVA_BASE}
	fi

}

src_compile() {
	if [ -f Makefile ] || [ -f GNUmakefile ] || [ -f makefile ]; then
		emake AR="$(tc-getAR)" RANLIB="$(tc-getRANLIB)" || die "emake failed"
	fi
}
