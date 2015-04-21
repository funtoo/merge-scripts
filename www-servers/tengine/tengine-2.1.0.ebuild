# Distributed under the terms of the GNU General Public License v2

EAPI="5"

GENTOO_DEPEND_ON_PERL="no"
# Passenger have support for jruby and rbx
USE_RUBY="ruby19 ruby20 ruby21 ruby22"
RUBY_OPTIONAL="yes"

# Encrypted Session (https://github.com/openresty/encrypted-session-nginx-module)
ENCRYPTED_SESSION_A="openresty"
ENCRYPTED_SESSION_PN="encrypted-session-nginx-module"
ENCRYPTED_SESSION_PV="0.03"
ENCRYPTED_SESSION_P="${ENCRYPTED_SESSION_PN}-${ENCRYPTED_SESSION_PV}"
ENCRYPTED_SESSION_URI="https://github.com/${ENCRYPTED_SESSION_A}/${ENCRYPTED_SESSION_PN}/archive/v${ENCRYPTED_SESSION_PV}.tar.gz"
ENCRYPTED_SESSION_WD="${WORKDIR}/${ENCRYPTED_SESSION_P}"

# Fancy Index (https://github.com/aperezdc/ngx-fancyindex)
FANCYINDEX_A="aperezdc"
FANCYINDEX_PN="ngx-fancyindex"
FANCYINDEX_PV="0.3.5"
FANCYINDEX_P="${FANCYINDEX_PN}-${FANCYINDEX_PV}"
FANCYINDEX_URI="https://github.com/${FANCYINDEX_A}/${FANCYINDEX_PN}/archive/v${FANCYINDEX_PV}.tar.gz"
FANCYINDEX_WD="${WORKDIR}/${FANCYINDEX_P}"

# MogileFS Client (http://www.grid.net.ru/nginx/mogilefs.en.html)
MOGILEFS_A="vkholodkov"
MOGILEFS_PN="nginx-mogilefs-module"
MOGILEFS_PV="1.0.4"
MOGILEFS_P="${MOGILEFS_PN}-${MOGILEFS_PV}"
MOGILEFS_URI="https://github.com/${MOGILEFS_A}/${MOGILEFS_PN}/archive/${MOGILEFS_PV}.tar.gz"
MOGILEFS_WD="${WORKDIR}/${MOGILEFS_P}"

# Nginx Development Kit (NDK) (https://github.com/simpl/ngx_devel_kit)
NDK_A="simpl"
NDK_PN="ngx_devel_kit"
NDK_PV="0.2.19"
NDK_P="${NDK_PN}-${NDK_PV}"
NDK_URI="https://github.com/${NDK_A}/${NDK_PN}/archive/v${NDK_PV}.tar.gz"
NDK_WD="${WORKDIR}/${NDK_P}"

# Phusion Passenger (https://github.com/phusion/passenger)
PASSENGER_A="phusion"
PASSENGER_PN="passenger"
PASSENGER_PV="5.0.6"
PASSENGER_P="${PASSENGER_PN}-release-${PASSENGER_PV}"
PASSENGER_URI="https://github.com/${PASSENGER_A}/${PASSENGER_PN}/archive/release-${PASSENGER_PV}.tar.gz"
PASSENGER_WD="${WORKDIR}/${PASSENGER_P}/ext/nginx"

inherit eutils flag-o-matic perl-module ruby-ng ssl-cert toolchain-funcs user

DESCRIPTION="Robust, small and high performance http and reverse proxy server"
HOMEPAGE="http://tengine.taobao.org"
SRC_URI="http://${PN}.taobao.org/download/${P}.tar.gz
	tengine_external_modules_http_encrypted_session? (
		${ENCRYPTED_SESSION_URI} -> ${ENCRYPTED_SESSION_P}.tar.gz )
	tengine_external_modules_http_fancyindex? (
		${FANCYINDEX_URI} -> ${FANCYINDEX_P}.tar.gz )
	tengine_external_modules_http_mogilefs? (
		${MOGILEFS_URI} -> ${MOGILEFS_P}.tar.gz )
	tengine_external_modules_http_ndk? (
		${NDK_URI} -> ${NDK_P}.tar.gz )
	tengine_external_modules_http_passenger? (
		${PASSENGER_URI} -> ${PASSENGER_P}.tar.gz )"

LICENSE="BSD-2
	tengine_external_modules_http_encrypted_session? ( BSD )
	tengine_external_modules_http_fancyindex? ( BSD )
	tengine_external_modules_http_mogilefs? ( BSD-2 )
	tengine_external_modules_http_ndk? ( BSD )
	tengine_external_modules_http_passenger? ( MIT )"

RESTRICT="mirror"

SLOT="0"
KEYWORDS="*"

TENGINE_UPSTREAM="upstream_check upstream_consistent_hash upstream_keepalive
	upstream_rbtree"

TENGINE_UPSTREAM_SHARED="upstream_ip_hash upstream_least_conn
	upstream_session_sticky"

TENGINE_MODULES_STANDARD="auth_basic geo gzip proxy ssi ssl stub_status
	${TENGINE_UPSTREAM}"

TENGINE_MODULES_STANDARD_SHARED="
	access autoindex browser charset_filter empty_gif fastcgi footer_filter
	limit_conn limit_req map memcached referer reqstat rewrite scgi
	split_clients trim_filter userid_filter user_agent uwsgi
	${TENGINE_UPSTREAM_SHARED}"

TENGINE_MODULES_OPTIONAL="
	concat dav degradation gunzip gzip_static perl realip spdy"

TENGINE_MODULES_OPTIONAL_SHARED="
	addition flv geoip image_filter lua mp4 random_index
	secure_link slice tfs sub sysguard xslt"

TENGINE_MODULES_MAIL="imap pop3 smtp"

# encrypted_session depend on ndk.
# place ndk before modules that depend on it.
TENGINE_MODULES_EXTERNAL="ndk encrypted_session
	fancyindex mogilefs passenger"

IUSE="+aio +dso +http +http-cache +pcre +poll +select +syslog
	backtrace debug google_perftools ipv6 jemalloc libatomic luajit
	pcre-jit rtmp rtsig ssl vim-syntax"

for module in $TENGINE_MODULES_STANDARD ; do
	IUSE+=" +tengine_static_modules_http_${module}"
done

for module in $TENGINE_MODULES_STANDARD_SHARED ; do
	IUSE+=" tengine_shared_modules_http_${module}
		+tengine_static_modules_http_${module}"
done

for module in $TENGINE_MODULES_OPTIONAL ; do
	IUSE+=" +tengine_static_modules_http_${module}"
done

for module in $TENGINE_MODULES_OPTIONAL_SHARED ; do
	IUSE+=" tengine_shared_modules_http_${module}
		tengine_static_modules_http_${module}"
done

for module in $TENGINE_MODULES_MAIL ; do
	IUSE+=" tengine_modules_mail_${module}"
done

for module in $TENGINE_MODULES_EXTERNAL ; do
	IUSE+=" tengine_external_modules_http_${module}"
done

RDEPEND="http-cache? ( dev-libs/openssl )
	jemalloc? ( dev-libs/jemalloc )
	pcre? ( dev-libs/libpcre )
	pcre-jit? ( dev-libs/libpcre[jit] )
	ssl? ( dev-libs/openssl )

	tengine_shared_modules_http_geoip? ( dev-libs/geoip )
	tengine_shared_modules_http_image_filter? ( media-libs/gd[jpeg,png] )
	tengine_shared_modules_http_lua? ( !luajit? ( dev-lang/lua )
		luajit? ( dev-lang/luajit ) )
	tengine_shared_modules_http_rewrite? ( dev-libs/libpcre )
	tengine_shared_modules_http_secure_link? ( dev-libs/openssl )
	tengine_shared_modules_http_tfs? ( dev-libs/yajl )
	tengine_shared_modules_http_xslt? ( dev-libs/libxml2
		dev-libs/libxslt )

	tengine_static_modules_http_geo? ( dev-libs/geoip )
	tengine_static_modules_http_geoip? ( dev-libs/geoip )
	tengine_static_modules_http_gunzip? ( sys-libs/zlib )
	tengine_static_modules_http_gzip? ( sys-libs/zlib )
	tengine_static_modules_http_gzip_static? ( sys-libs/zlib )
	tengine_static_modules_http_image_filter? ( media-libs/gd[jpeg,png] )
	tengine_static_modules_http_lua? ( !luajit? ( dev-lang/lua )
		luajit? ( dev-lang/luajit ) )
	tengine_static_modules_http_perl? ( dev-lang/perl )
	tengine_static_modules_http_rewrite? ( dev-libs/libpcre )
	tengine_static_modules_http_secure_link? ( dev-libs/openssl )
	tengine_static_modules_http_spdy? ( dev-libs/openssl )
	tengine_static_modules_http_tfs? ( dev-libs/yajl )
	tengine_static_modules_http_xslt? ( dev-libs/libxml2
		dev-libs/libxslt )
	tengine_external_modules_http_passenger? (
		|| ( $(ruby_implementation_depend ruby19)
			$(ruby_implementation_depend ruby20)
			$(ruby_implementation_depend ruby21)
			$(ruby_implementation_depend ruby22) )
		dev-ruby/rake
		!!www-apache/passenger )"

DEPEND="${RDEPEND}
	arm? ( dev-libs/libatomic_ops )
	libatomic? ( dev-libs/libatomic_ops )"

PDEPEND="vim-syntax? ( app-vim/nginx-syntax )"

REQUIRED_USE="pcre-jit? ( pcre )
	tengine_external_modules_http_encrypted_session? ( ssl
		tengine_external_modules_http_ndk )"

for module in $TENGINE_MODULES_{STANDARD,OPTIONAL}_SHARED ; do
	REQUIRED_USE+=" tengine_shared_modules_http_${module}? ( !tengine_static_modules_http_${module} )"
done

S="${WORKDIR}/${P}"

pkg_setup() {
	TENGINE_HOME="${EROOT}var/lib/${PN}"
	TENGINE_HOME_TMP="${TENGINE_HOME}/tmp"

	if egetent group ${PN} > /dev/null ; then
		elog ${PN} group already exist. group creation step skipped.
	else
		enewgroup ${PN} > /dev/null && \
		elog ${PN} group created by portage.
	fi

	if egetent passwd ${PN} > /dev/null ; then
		elog ${PN} user already exist. user creation step skipped.
	else
		enewuser ${PN} -1 -1 "${TENGINE_HOME}" ${PN} > /dev/null && \
		elog ${PN} user with ${TENGINE_HOME} home created by portage.
	fi

	if use libatomic ; then
		ewarn "GCC 4.1+ features built-in atomic operations."
		ewarn "Using libatomic_ops is only needed if using"
		ewarn "a different compiler or a GCC prior to 4.1"
	fi

	if use_if_iuse tengine_external_modules_http_passenger ; then
		ruby-ng_pkg_setup
		use debug && append-flags -DPASSENGER_DEBUG
	fi

	if ! use http ; then
		ewarn "To actually disable all http-functionality you also have to disable"
		ewarn "all tengine http modules."
	fi
}

src_unpack() {
	# Prevent ruby-ng.eclass from messing with src_unpack
	default
}

src_prepare() {
	epatch "${FILESDIR}/${PN}-fix-perl-install-path.patch"

	sed -e "s;NGX_CONF_PREFIX/nginx.conf;NGX_CONF_PREFIX/tengine.conf;" \
		-i "${S}/auto/install" || die

	if ! use_if_iuse tengine_static_modules_http_charset_filter || ! use_if_iuse tengine_shared_modules_http_charset_filter ; then
		sed -e "s;--without-http_charset_module;--without-http_charset_filter_module;g" \
			-i "${S}/auto/options" || die
	fi

	if ! use_if_iuse tengine_static_modules_http_userid_filter || ! use_if_iuse tengine_shared_modules_http_userid_filter ; then
		sed -e "s;--without-http_userid_module;--without-http_userid_filter_module;g" \
			-i "${S}/auto/options" || die
	fi

	if ! use_if_iuse tengine_static_modules_http_rbtree ; then
		sed -e "s;--without-http-upstream-rbtree;--without-http_upstream_rbtree_module;g" \
			-i "${S}/auto/options" || die
	fi

	find auto/ -type f -print0 | xargs -0 sed -i 's;\&\& make;\&\& \\$(MAKE);' || die
	# We have config protection, don't rename etc files
	sed -e 's;.default;;' \
		-i "${S}/auto/install" || die
	# Remove useless files
	sed -e "/koi-/d" \
		-e "/win-/d" \
		-i "${S}/auto/install" || die

	# Don't install to /etc/tengine/ if not in use
	local module
	for module in fastcgi scgi uwsgi ; do
		if ! use_if_iuse tengine_static_modules_http_${module} && \
			! use_if_iuse tengine_shared_modules_http_${module} ; then
				sed -e "/${module}/d" \
					-i auto/install || die
		fi
	done

	if use_if_iuse tengine_external_modules_http_passenger ; then
		cd ../"${PASSENGER_P}" ;

		# Use proper toolchain-funcs methods
		sed -e "/^CC/ s/=.*$/= '$(tc-getCC)'/" \
			-e "/^CXX/ s/=.*$/= '$(tc-getCXX)'/" \
			-i "build/basics.rb" || die

		# Fix hard-coded use of AR
		sed -e "s;ar cru;"$(tc-getAR)" cru;" \
			-i "build/cplusplus_support.rb" || die

		epatch "${FILESDIR}"/passenger/passenger-contenthandler.patch
		epatch "${FILESDIR}"/passenger/passenger-gentoo.patch
		epatch "${FILESDIR}"/passenger/passenger-ldflags.patch

		sed -e "s;/buildout/agents;/agents;" \
			-i "ext/common/ResourceLocator.h" || die

		sed -e '/passenger-install-apache2-module/d' \
			-e "/passenger-install-nginx-module/d" \
			-i "lib/phusion_passenger/packaging.rb" || die

		rm "bin/passenger-install-apache2-module" \
			"bin/passenger-install-nginx-module" || \
			die "Unable to remove nginx and apache2 installation scripts."

		cd "${PASSENGER_WD}" ;
		_ruby_each_implementation passenger_premake
	fi
}

src_configure() {
	local tengine_configure= http_enabled= mail_enabled=

	use aio && tengine_configure+=" --with-file-aio --with-aio_module"
	use backtrace && tengine_configure+=" --with-backtrace_module"
	use debug && tengine_configure+=" --with-debug"
	use google_perftools && tengine_configure+=" --with-google_perftools_module"
	use ipv6 && tengine_configure+=" --with-ipv6"
	use jemalloc && tengine_configure+=" --with-jemalloc"
	use libatomic && tengine_configure+=" --with-libatomic"
	use pcre && tengine_configure+=" --with-pcre"
	use pcre-jit && tengine_configure+=" --with-pcre-jit"
	use rtsig && tengine_configure+=" --with-rtsig_module"

	use dso || tengine_configure+=" --without-dso"
	use syslog || tengine_configure+=" --without-syslog"

	for module in $TENGINE_MODULES_{STANDARD,STANDARD_SHARED} ; do
		if use tengine_static_modules_http_${module} && \
			! use_if_iuse tengine_shared_modules_http_${module} ; then
				http_enabled=1
		else
			tengine_configure+=" --without-http_${module}_module"
		fi
	done

	for module in $TENGINE_MODULES_STANDARD_SHARED ; do
		if use dso && \
			use_if_iuse tengine_shared_modules_http_${module} && \
			! use_if_iuse tengine_static_modules_http_${module} ; then
				http_enabled=1
				tengine_configure+=" --with-http_${module}_module=shared"
		elif use dso && \
			! use_if_iuse tengine_shared_modules_http_${module} && \
			! use_if_iuse tengine_static_modules_http_${module} ; then
				tengine_configure+=" --without-http_${module}_module"
		fi
	done

	for module in $TENGINE_MODULES_{OPTIONAL,OPTIONAL_SHARED} ; do
		if use_if_iuse tengine_static_modules_http_${module} && \
			! use_if_iuse tengine_shared_modules_http_${module} ; then
				http_enabled=1
				tengine_configure+=" --with-http_${module}_module"
		fi
	done

	for module in $TENGINE_MODULES_OPTIONAL_SHARED ; do
		if use dso && use_if_iuse tengine_shared_modules_http_${module} && \
			! use_if_iuse tengine_static_modules_http_${module} ; then
				http_enabled=1
				tengine_configure+=" --with-http_${module}_module=shared"
		fi
	done

	if use_if_iuse tengine_static_modules_http_fastcgi || \
		use_if_iuse tengine_static_modules_http_fastcgi ; then
			tengine_configure+=" --with-http_realip_module"
	fi

	for module in $TENGINE_MODULES_EXTERNAL ; do
		if use_if_iuse tengine_external_modules_http_${module} ; then
			http_enabled=1
			local module_wd=${module^^}_WD
			tengine_configure+=" --add-module=${!module_wd}"
		fi
	done

	if use http || use http-cache ; then
		http_enabled=1
	fi

	if [[ -n "${http_enabled}" ]] ; then
		use http-cache || tengine_configure+=" --without-http-cache"
		use ssl && tengine_configure+=" --with-http_ssl_module"
	else
		tengine_configure+=" --without-http --without-http-cache"
	fi

	for module in $TENGINE_MODULES_MAIL ; do
		if use_if_iuse tengine_modules_mail_${module}; then
			mail_enabled=1
		else
			tengine_configure+=" --without-mail_${module}_module"
		fi
	done

	if [[ -n "${mail_enabled}" ]] ; then
		tengine_configure+=" --with-mail"
		use ssl && tengine_configure+=" --with-mail_ssl_module"
	fi

	# https://bugs.gentoo.org/286772
	export LANG=C LC_ALL=C
	tc-export CC

	if ! use prefix ; then
		tengine_configure+=" --user=${PN} --group=${PN}"
	fi

	./configure \
		--sbin-path="${EPREFIX}/usr/sbin/${PN}" \
		--dso-path="${EPREFIX}/${TENGINE_HOME}/modules" \
		--dso-tool-path="${EPREFIX}/usr/sbin/dso_tool" \
		--prefix="${EPREFIX}/usr" \
		--conf-path="${EPREFIX}/etc/${PN}/${PN}.conf" \
		--error-log-path="${EPREFIX}/var/log/${PN}/error_log" \
		--pid-path="${EPREFIX}/run/${PN}.pid" \
		--lock-path="${EPREFIX}/run/lock/${PN}.lock" \
		--with-cc-opt="-I${EROOT}usr/include" \
		--with-ld-opt="-L${EROOT}usr/$(get_libdir)" \
		--http-log-path="${EPREFIX}/var/log/${PN}/access_log" \
		--http-client-body-temp-path="${EPREFIX}/${TENGINE_HOME_TMP}/client" \
		--http-proxy-temp-path="${EPREFIX}/${TENGINE_HOME_TMP}/proxy" \
		--http-fastcgi-temp-path="${EPREFIX}/${TENGINE_HOME_TMP}/fastcgi" \
		--http-scgi-temp-path="${EPREFIX}/${TENGINE_HOME_TMP}/scgi" \
		--http-uwsgi-temp-path="${EPREFIX}/${TENGINE_HOME_TMP}/uwsgi" \
		$(use_with poll poll_module) \
		$(use_with select select_module) \
		${tengine_configure} || die

	# A purely cosmetic change that makes tengine -V more readable.
	# This can be good if people outside the gentoo community would
	# troubleshoot and question the user setup.
	sed -e "s;${WORKDIR};external_module;g" \
		-i "${S}/objs/ngx_auto_config.h" || die
}

src_compile() {
	# https://bugs.gentoo.org/286772
	export LANG=C LC_ALL=C
	emake LINK="${CC} ${LDFLAGS}" OTHERLDFLAGS="${LDFLAGS}"
}

passenger_premake() {
	# Dirty spike to make passenger compilation each-ruby compatible
	mkdir -p "${S}"
	cp -r "${PASSENGER_P}" "${S}"
	cp -r "${PN}-${PV}" "${S}"
	cd "${S}/${PASSENGER_P}"
	sed -e "s;#{PlatformInfo.ruby_command};${RUBY};g" \
		-i "build/ruby_extension.rb" \
		-i "lib/phusion_passenger/native_support.rb" || die
	append-cflags $(test-flags-CC -fno-strict-aliasing -Wno-unused-result)
	append-cxxflags $(test-flags-CXX -fno-strict-aliasing -Wno-unused-result -fPIC)
	rake -m nginx || die "Passenger premake for ${RUBY} failed!"
}

passenger_install() {
	# Dirty spike to make passenger installation each-ruby compatible
	cd "${PASSENGER_WD}"
	rake -m fakeroot \
	NATIVE_PACKAGING_METHOD=ebuild \
	FS_PREFIX="${EROOT}usr" \
	FS_DATADIR="${EROOT}usr/libexec" \
	FS_DOCDIR="${EROOT}usr/share/doc/${P}" \
	FS_LIBDIR="${EROOT}usr/$(get_libdir)" \
	RUBYLIBDIR="$(ruby_rbconfig_value 'archdir')" \
	RUBYARCHDIR="$(ruby_rbconfig_value 'archdir')" \
	|| die "Passenger installation for ${RUBY} failed!"
}

src_install() {
	if use_if_iuse tengine_static_modules_http_perl ; then
		sed -e '/CORE_LINK/{ N; s/CORE_LINK=.\(.*\).$/CORE_LINK="\1"/ }' \
			-i "${S}/objs/dso_tool" || die
	fi

	emake DESTDIR="${D}" install

	insinto "${EROOT}etc/${PN}"
	doins "${FILESDIR}/${PN}.conf"

	newinitd "${FILESDIR}/${PN}.initd" "${PN}"

	keepdir "${EROOT}etc/${PN}"/sites-{available,enabled}
	insinto "${EROOT}etc/${PN}/sites-available"
	doins "${FILESDIR}/sites-available/localhost"
	dodir "${EROOT}usr/share/tengine/html"
	insinto "${EROOT}usr/share/tengine/html"
	doins "${FILESDIR}/example/index.html"
	doins "${FILESDIR}/example/powered-by-funtoo.png"
	doins "${FILESDIR}/example/tengine-logo.png"

	newman man/nginx.8 ${PN}.8
	dodoc CHANGES* README

	# just keepdir. do not copy the default htdocs files (bug #449136)
	keepdir ${EROOT}var/www/localhost
	rm -r "${D}/usr/html" || die

	# set up a list of directories to keep
	local keepdir_list="${TENGINE_HOME_TMP}/client"
	local module
	for module in proxy fastcgi scgi uwsgi ; do
		use_if_iuse tengine_static_modules_http_${module} && \
			keepdir_list+=" ${TENGINE_HOME_TMP}/${module}"
	done

	# logrotate
	if use syslog ; then
		insinto "${EROOT}etc/logrotate.d"
		newins "${FILESDIR}/${PN}.logrotate" "${PN}"
		if [[ ! -d "${EROOT}var/log/${PN}" ]] ; then
			keepdir_list+=" ${EROOT}var/log/${PN}"
		fi
	fi

	keepdir ${keepdir_list}
	fperms 0700 ${keepdir_list}
	fowners ${PN}:${PN} ${keepdir_list}

	if use_if_iuse tengine_static_modules_http_perl ; then
		cd "${S}/objs/src/http/modules/perl"
		einstall DESTDIR="${D}" INSTALLDIRS=vendor
		perl_delete_localpod
	fi

	if use_if_iuse tengine_external_modules_http_encrypted_session ; then
		docinto "${ENCRYPTED_SESSION_P}"
		dodoc "${ENCRYPTED_SESSION_WD}/README"
	fi

	if use_if_iuse tengine_external_modules_http_fancyindex ; then
		docinto "${FANCYINDEX_P}"
		dodoc "${FANCYINDEX_WD}/README.rst"
	fi

	if use_if_iuse tengine_external_modules_http_ndk ; then
		docinto "${NDK_P}"
		dodoc "${NDK_WD}/README"
	fi

	if use_if_iuse tengine_external_modules_http_passenger ; then
	_ruby_each_implementation passenger_install
	fi
}

pkg_preinst() {
	if [[ ! -d "${EROOT}etc/${PN}/sites-available" ]] ; then
		first_install=yes
	else
		first_install=no
	fi
}

pkg_postinst() {
	if [[ "${first_install}" = "yes" ]] && \
		[[ ! -e "${EROOT}etc/${PN}/sites-enabled/localhost" ]] ; then
			einfo "Enabling example Web site (see http://127.0.0.1)"
			ln -s "../sites-available/localhost" \
				"${EROOT}etc/${PN}/sites-enabled/localhost" || \
				die
	fi

	if use ssl ; then
		if [[ ! -f "${EROOT}etc/ssl/${PN}/${PN}.key" ]] ; then
			install_cert /etc/ssl/${PN}/${PN}
			use prefix || chown ${PN}:${PN} \
				"${EROOT}etc/ssl/${PN}"/${PN}.{crt,csr,key,pem}
		fi
	fi

	einfo "If tengine complains about insufficient number of open files at"
	einfo "start, ensure that you have a correct /etc/security/limits.conf"
	einfo "and then do relogin to your system to ensure that the new max"
	einfo "open file limits are active. Then try restarting tengine again."

	if use_if_iuse tengine_external_modules_http_passenger ; then
		ewarn "Please, keep notice, that 'passenger_root' directive"
		ewarn "should point to exact location of 'locations.ini'"
		ewarn "file from this package (i.e. it should be full path)"
		ewarn "It is installed (by default) to"
		ewarn "${EROOT}usr/libexec/passenger/locations.ini"
	fi

	# If the tengine user can't change into or read the dir, display a warning.
	# If su is not available we display the warning nevertheless since
	# we can't check properly
	su -s /bin/sh -c "cd ${EROOT}var/log/${PN} && ls" ${PN} >&/dev/null
	if [[ $? -ne 0 ]] ; then
		ewarn "Please make sure that the tengine user or group has"
		ewarn "at least 'rx' permissions (default on fresh install)"
		ewarn "on ${EROOT}var/log/${PN} directory."
		ewarn "Otherwise you end up with empty log files"
		ewarn "after a logrotate."
	fi
}

pkg_prerm() {
	if [[ -h "${EROOT}etc/${PN}/sites-enabled/localhost" ]] ; then
		rm ${EROOT}etc/${PN}/sites-enabled/localhost || die
	fi
}
