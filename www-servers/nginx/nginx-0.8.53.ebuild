# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-servers/nginx/nginx-0.8.53.ebuild,v 1.2 2010/12/21 19:18:41 phajdan.jr Exp $

EAPI="2"

# Maintainer notes:
# - http_rewrite-independent pcre-support makes sense for matching locations without an actual rewrite
# - any http-module activates the main http-functionality and overrides USE=-http
# - keep the following 3 requirements in mind before adding external modules:
#   * alive upstream
#   * sane packaging
#   * builds cleanly
# - TODO: test the google-perftools module (included in vanilla tarball)

# prevent perl-module from adding automagic perl DEPENDs
GENTOO_DEPEND_ON_PERL="no"

# http_headers_more (http://github.com/agentzh/headers-more-nginx-module, BSD license)
HTTP_HEADERS_MORE_MODULE_PV="0.13"
HTTP_HEADERS_MORE_MODULE_P="ngx-http-headers-more-${HTTP_HEADERS_MORE_MODULE_PV}"
HTTP_HEADERS_MORE_MODULE_SHA1="9508330"

# http_passenger (http://www.modrails.com/, MIT license)
# TODO: currently builds some stuff in src_configure
PASSENGER_PV="2.2.15"
USE_RUBY="ruby18"
RUBY_OPTIONAL="yes"

# http_push (http://pushmodule.slact.net/, MIT license)
HTTP_PUSH_MODULE_P="nginx_http_push_module-0.692"

# http_cache_purge (http://labs.frickle.com/nginx_ngx_cache_purge/, BSD-2 license)
HTTP_CACHE_PURGE_MODULE_P="ngx_cache_purge-1.2"

inherit eutils ssl-cert toolchain-funcs perl-module ruby-ng flag-o-matic

DESCRIPTION="Robust, small and high performance http and reverse proxy server"
HOMEPAGE="http://nginx.net/
	http://www.modrails.com/
	http://pushmodule.slact.net/
	http://labs.frickle.com/nginx_ngx_cache_purge/"
SRC_URI="http://sysoev.ru/nginx/${P}.tar.gz
	nginx_modules_http_headers_more? ( http://github.com/agentzh/headers-more-nginx-module/tarball/v${HTTP_HEADERS_MORE_MODULE_PV} -> ${HTTP_HEADERS_MORE_MODULE_P}.tar.gz )
	nginx_modules_http_passenger? ( mirror://rubyforge/passenger/passenger-${PASSENGER_PV}.tar.gz )
	nginx_modules_http_push? ( http://pushmodule.slact.net/downloads/${HTTP_PUSH_MODULE_P}.tar.gz )
	nginx_modules_http_cache_purge? ( http://labs.frickle.com/files/${HTTP_CACHE_PURGE_MODULE_P}.tar.gz )"

LICENSE="BSD BSD-2 GPL-2 MIT"
SLOT="0"
KEYWORDS="~amd64 ~ppc x86 ~x86-fbsd"

NGINX_MODULES_STD="access auth_basic autoindex browser charset empty_gif fastcgi
geo gzip limit_req limit_zone map memcached proxy referer rewrite scgi ssi
split_clients upstream_ip_hash userid uwsgi"
NGINX_MODULES_OPT="addition dav degradation flv geoip gzip_static image_filter
perl random_index realip secure_link stub_status sub xslt"
NGINX_MODULES_MAIL="imap pop3 smtp"
NGINX_MODULES_3RD="http_cache_purge http_headers_more http_passenger http_push"

IUSE="aio debug +http +http-cache ipv6 libatomic +pcre ssl vim-syntax"

for mod in $NGINX_MODULES_STD; do
	IUSE="${IUSE} +nginx_modules_http_${mod}"
done

for mod in $NGINX_MODULES_OPT; do
	IUSE="${IUSE} nginx_modules_http_${mod}"
done

for mod in $NGINX_MODULES_MAIL; do
	IUSE="${IUSE} nginx_modules_mail_${mod}"
done

for mod in $NGINX_MODULES_3RD; do
	IUSE="${IUSE} nginx_modules_${mod}"
done

CDEPEND="
	pcre? ( >=dev-libs/libpcre-4.2 )
	ssl? ( dev-libs/openssl )
	http-cache? ( userland_GNU? ( dev-libs/openssl ) )
	nginx_modules_http_geo? ( dev-libs/geoip )
	nginx_modules_http_gzip? ( sys-libs/zlib )
	nginx_modules_http_gzip_static? ( sys-libs/zlib )
	nginx_modules_http_image_filter? ( media-libs/gd )
	nginx_modules_http_perl? ( >=dev-lang/perl-5.8 )
	nginx_modules_http_rewrite? ( >=dev-libs/libpcre-4.2 )
	nginx_modules_http_secure_link? ( userland_GNU? ( dev-libs/openssl ) )
	nginx_modules_http_xslt? ( dev-libs/libxml2 dev-libs/libxslt )
	nginx_modules_http_passenger? (
		$(ruby_implementation_depend ruby18)
		>=dev-ruby/rubygems-0.9.0
		>=dev-ruby/rake-0.8.1
		>=dev-ruby/fastthread-1.0.1
		>=dev-ruby/rack-1.0.0
	)"
RDEPEND="${CDEPEND}"
DEPEND="${CDEPEND}
	arm? ( dev-libs/libatomic_ops )
	libatomic? ( dev-libs/libatomic_ops )"
PDEPEND="vim-syntax? ( app-vim/nginx-syntax )"

pkg_setup() {
	ebegin "Creating nginx user and group"
	enewgroup ${PN}
	enewuser ${PN} -1 -1 -1 ${PN}
	eend ${?}

	if use ipv6; then
		ewarn "Note that ipv6 support in nginx is still experimental."
		ewarn "Be sure to read comments on gentoo bug #274614"
		ewarn "http://bugs.gentoo.org/show_bug.cgi?id=274614"
	fi

	if use libatomic; then
		ewarn "GCC 4.1+ features built-in atomic operations."
		ewarn "Using libatomic_ops is only needed if using"
		ewarn "a different compiler or a GCC prior to 4.1"
	fi

	if [[ -n $NGINX_ADD_MODULES ]]; then
		ewarn "You are building custom modules via \$NGINX_ADD_MODULES!"
		ewarn "This nginx installation is not supported!"
		ewarn "Make sure you can reproduce the bug without those modules"
		ewarn "_before_ reporting bugs."
	fi

	if use nginx_modules_http_passenger; then
		ruby-ng_pkg_setup
		use debug && append-flags -DPASSENGER_DEBUG
	fi

	if use !http; then
		ewarn "To actually disable all http-functionality you also have to disable"
		ewarn "all nginx http modules."
	fi
}

src_unpack() {
	# prevent ruby-ng.eclass from messing with src_unpack
	default
}

src_prepare() {
	sed -i 's/ make/ \\$(MAKE)/' "${S}"/auto/lib/perl/make

	if use nginx_modules_http_passenger; then
		cd "${WORKDIR}"/passenger-${PASSENGER_PV}
		epatch "${FILESDIR}"/passenger-CFLAGS.patch
	fi
}

src_configure() {
	local myconf= http_enabled= mail_enabled=

	use aio && myconf="${myconf} --with-file-aio --with-aio_module"
	use debug && myconf="${myconf} --with-debug"
	use ipv6 && myconf="${myconf} --with-ipv6"
	use libatomic && myconf="${myconf} --with-libatomic"
	use pcre && myconf="${myconf} --with-pcre"

	# HTTP modules
	for mod in $NGINX_MODULES_STD; do
		if use nginx_modules_http_${mod}; then
			http_enabled=1
		else
			myconf="${myconf} --without-http_${mod}_module"
		fi
	done

	for mod in $NGINX_MODULES_OPT; do
		if use nginx_modules_http_${mod}; then
			http_enabled=1
			myconf="${myconf} --with-http_${mod}_module"
		fi
	done

	if use nginx_modules_http_fastcgi; then
		myconf="${myconf} --with-http_realip_module"
	fi

	# third-party modules
	if use nginx_modules_http_headers_more; then
		http_enabled=1
		myconf="${myconf} --add-module=${WORKDIR}/agentzh-headers-more-nginx-module-${HTTP_HEADERS_MORE_MODULE_SHA1}"
	fi

	if use nginx_modules_http_passenger; then
		http_enabled=1
		myconf="${myconf} --add-module=${WORKDIR}/passenger-${PASSENGER_PV}/ext/nginx"
	fi

	if use nginx_modules_http_push; then
		http_enabled=1
		myconf="${myconf} --add-module=${WORKDIR}/${HTTP_PUSH_MODULE_P}"
	fi

	if use nginx_modules_http_cache_purge; then
		http_enabled=1
		myconf="${myconf} --add-module=${WORKDIR}/${HTTP_CACHE_PURGE_MODULE_P}"
	fi

	if use http || use http-cache; then
		http_enabled=1
	fi

	if [ $http_enabled ]; then
		use http-cache || myconf="${myconf} --without-http-cache"
		use ssl && myconf="${myconf} --with-http_ssl_module"
	else
		myconf="${myconf} --without-http --without-http-cache"
	fi

	# MAIL modules
	for mod in $NGINX_MODULES_MAIL; do
		if use nginx_modules_mail_${mod}; then
			mail_enabled=1
		else
			myconf="${myconf} --without-mail_${mod}_module"
		fi
	done

	if [ $mail_enabled ]; then
		myconf="${myconf} --with-mail"
		use ssl && myconf="${myconf} --with-mail_ssl_module"
	fi

	# custom modules
	for mod in $NGINX_ADD_MODULES; do
		myconf="${myconf} --add-module=${mod}"
	done

	# http://bugs.gentoo.org/show_bug.cgi?id=286772
	export LANG=C LC_ALL=C
	tc-export CC

	./configure \
		--prefix=/usr \
		--sbin-path=/usr/sbin/nginx \
		--conf-path=/etc/${PN}/${PN}.conf \
		--error-log-path=/var/log/${PN}/error_log \
		--pid-path=/var/run/${PN}.pid \
		--lock-path=/var/lock/nginx.lock \
		--user=${PN} --group=${PN} \
		--with-cc-opt="-I${ROOT}usr/include" \
		--with-ld-opt="-L${ROOT}usr/lib" \
		--http-log-path=/var/log/${PN}/access_log \
		--http-client-body-temp-path=/var/tmp/${PN}/client \
		--http-proxy-temp-path=/var/tmp/${PN}/proxy \
		--http-fastcgi-temp-path=/var/tmp/${PN}/fastcgi \
		--http-scgi-temp-path=/var/tmp/${PN}/scgi \
		--http-uwsgi-temp-path=/var/tmp/${PN}/uwsgi \
		${myconf} || die "configure failed"
}

src_compile() {
	# http://bugs.gentoo.org/show_bug.cgi?id=286772
	export LANG=C LC_ALL=C
	emake LINK="${CC} ${LDFLAGS}" OTHERLDFLAGS="${LDFLAGS}" || die "emake failed"
}

src_install() {
	keepdir /var/log/${PN} /var/tmp/${PN}/{client,proxy,fastcgi,scgi,uwsgi}

	dosbin objs/nginx
	newinitd "${FILESDIR}"/nginx.init-r2 nginx

	cp "${FILESDIR}"/nginx.conf-r4 conf/nginx.conf
	rm conf/win-utf conf/koi-win conf/koi-utf

	dodir /etc/${PN}
	insinto /etc/${PN}
	doins conf/*

	dodoc CHANGES* README

	# logrotate
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/nginx.logrotate nginx

	if use nginx_modules_http_perl; then
		cd "${S}"/objs/src/http/modules/perl/
		einstall DESTDIR="${D}" INSTALLDIRS=vendor || die "failed to install perl stuff"
		fixlocalpod
	fi

	if use nginx_modules_http_push; then
		docinto ${HTTP_PUSH_MODULE_P}
		dodoc "${WORKDIR}"/${HTTP_PUSH_MODULE_P}/{changelog.txt,protocol.txt,README}
	fi

	if use nginx_modules_http_cache_purge; then
		docinto ${HTTP_CACHE_PURGE_MODULE_P}
		dodoc "${WORKDIR}"/${HTTP_CACHE_PURGE_MODULE_P}/{CHANGES,README}
	fi

	if use nginx_modules_http_passenger; then
		# passengers Rakefile is so horribly broken that we have to do it
		# manually
		cd "${WORKDIR}"/passenger-${PASSENGER_PV}

		export RUBY="ruby18"

		insinto $(${RUBY} -rrbconfig -e 'print Config::CONFIG["archdir"]')/phusion_passenger
		insopts -m 0755
		doins ext/phusion_passenger/*.so
		doruby -r lib/phusion_passenger

		exeinto /usr/bin
		doexe bin/passenger-memory-stats bin/passenger-status

		exeinto /usr/libexec/passenger/bin
		doexe bin/passenger-spawn-server

		exeinto /usr/libexec/passenger/ext/nginx
		doexe ext/nginx/HelperServer
	fi
}

pkg_postinst() {
	if use ssl; then
		if [ ! -f "${ROOT}"/etc/ssl/${PN}/${PN}.key ]; then
			install_cert /etc/ssl/${PN}/${PN}
			chown ${PN}:${PN} "${ROOT}"/etc/ssl/${PN}/${PN}.{crt,csr,key,pem}
		fi
	fi
}
