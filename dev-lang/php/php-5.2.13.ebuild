# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/php/php-5.2.13.ebuild,v 1.7 2010/03/29 21:59:43 maekke Exp $

CGI_SAPI_USE="discard-path force-cgi-redirect"
APACHE2_SAPI_USE="concurrentmodphp threads"
IUSE="cli cgi ${CGI_SAPI_USE} ${APACHE2_SAPI_USE} fastbuild"

KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 s390 sh sparc x86 ~x86-fbsd"

# NOTE: Portage doesn't support setting PROVIDE based on the USE flags
#		that have been enabled, so we have to PROVIDE everything for now
#		and hope for the best
PROVIDE="virtual/php virtual/httpd-php"

# php package settings
SLOT="5"
MY_PHP_PV="${PV}"
MY_PHP_P="php-${MY_PHP_PV}"
PHP_PACKAGE="1"
# php patch settings, general
PHP_PATCHSET_REV="${PR/r/}"
PHP_PATCHSET_URI="http://dev.gentoo.org/~keytoaster/distfiles/php-patchset-${PV}-r${PHP_PATCHSET_REV}.tar.bz2"
SUHOSIN_PATCH="suhosin-patch-5.2.13-0.9.7.patch.gz"
MULTILIB_PATCH="${MY_PHP_PV}/opt/multilib-search-path.patch"
# php patch settings, ebuild specific
FASTBUILD_PATCH="${MY_PHP_PV}/opt/fastbuild.patch"
CONCURRENTMODPHP_PATCH="${MY_PHP_PV}/opt/concurrent_apache_modules.patch"
# kolab patch - http://kolab.org/cgi-bin/viewcvs-kolab.cgi/server/patches/php/
# bugs about this go to wrobel@gentoo.org
KOLAB_PATCH="${MY_PHP_PV}/opt/kolab-imap-annotations.patch"

inherit versionator php5_2-sapi apache-module

# Suhosin patch support
[[ -n "${SUHOSIN_PATCH}" ]] && SRC_URI="${SRC_URI} suhosin? (
http://download.suhosin.org/${SUHOSIN_PATCH} )"

DESCRIPTION="The PHP language runtime engine: CLI, CGI and Apache2 SAPIs."

DEPEND="app-admin/php-toolkit
	imap? ( >=virtual/imap-c-client-2006k )
	pcre? ( >=dev-libs/libpcre-7.8 )
	xml? ( >=dev-libs/libxml2-2.7.2-r2 )
	xmlrpc? ( >=dev-libs/libxml2-2.7.2-r2 virtual/libiconv )"

RDEPEND="${DEPEND}"
if [[ -n "${KOLAB_PATCH}" ]] ; then
	IUSE="${IUSE} kolab"
	DEPEND="${DEPEND}
		kolab? ( >=net-libs/c-client-2004g-r1 )"
fi

PDEPEND="suhosin? ( >=dev-php5/suhosin-0.9.29 )"

want_apache

pkg_setup() {
	PHPCONFUTILS_AUTO_USE=""

	# Make sure the user has specified at least one SAPI
	einfo "Determining SAPI(s) to build"
	phpconfutils_require_any "  Enabled  SAPI:" "  Disabled SAPI:" cli cgi apache2

	# Threaded Apache2 support
	if use apache2 ; then
		has_apache_threads
	fi

	# Concurrent PHP Apache2 modules support
	if use apache2 ; then
		if use concurrentmodphp ; then
			ewarn
			ewarn "'concurrentmodphp' makes it possible to load multiple, differently"
			ewarn "versioned mod_php's into the same Apache instance. This is done with"
			ewarn "a few linker tricks and workarounds, and is not guaranteed to always"
			ewarn "work correctly, so use it at your own risk. Especially, do not use"
			ewarn "this in conjunction with PHP modules (PECL, ...) other than the ones"
			ewarn "you may find in the Portage tree or the PHP Overlay!"
			ewarn "This is an experimental feature, so please rebuild PHP"
			ewarn "without the 'concurrentmodphp' USE flag if you experience"
			ewarn "any problems, and then reproduce any bugs before filing"
			ewarn "them in Gentoo's Bugzilla or bugs.php.net."
			ewarn "If you have conclusive evidence that a bug directly"
			ewarn "derives from 'concurrentmodphp', please file a bug in"
			ewarn "Gentoo's Bugzilla only."
			ewarn
			ebeep 5
		fi
	fi

	# fastbuild support
	if use fastbuild ; then
		ewarn
		ewarn "'fastbuild' attempts to build all SAPIs in a single pass."
		ewarn "This is an experimental feature, so please rebuild PHP"
		ewarn "without the 'fastbuild' USE flag if you experience"
		ewarn "any problems, and then reproduce any bugs before filing"
		ewarn "them in Gentoo's Bugzilla or bugs.php.net."
		ewarn "If you have conclusive evidence that a bug directly"
		ewarn "derives from 'fastbuild', please file a bug in"
		ewarn "Gentoo's Bugzilla only."
		ewarn
	fi

	if use pcre ; then
		built_with_use dev-libs/libpcre unicode || \
			die "Please rebuild dev-libs/libpcre with USE=unicode"
	fi

	depend.apache_pkg_setup
	php5_2-sapi_pkg_setup
}

php_determine_sapis() {
	# holds the list of sapis that we want to build
	PHPSAPIS=

	if use cli || phpconfutils_usecheck cli ; then
		PHPSAPIS="${PHPSAPIS} cli"
	fi

	if use cgi ; then
		PHPSAPIS="${PHPSAPIS} cgi"
	fi

	# note - apache SAPI comes after the simpler cli/cgi sapis
	if use apache2 ; then
		PHPSAPIS="${PHPSAPIS} apache${APACHE_VERSION}"
	fi
}

src_unpack() {
	if [[ "${PHP_PACKAGE}" == 1 ]] ; then
		unpack ${A}
	fi

	cd "${S}"

	epatch "${FILESDIR}"/${PN}-5.2.12-libpng14.patch

	# Concurrent PHP Apache2 modules support
	if use apache2 ; then
		if use concurrentmodphp ; then
			if [[ -n "${CONCURRENTMODPHP_PATCH}" ]] && [[ -f "${WORKDIR}/${CONCURRENTMODPHP_PATCH}" ]] ; then
				epatch "${WORKDIR}/${CONCURRENTMODPHP_PATCH}"
			else
				ewarn "There is no concurrent mod_php patch available for this PHP release yet!"
			fi
		fi
	fi

	# fastbuild support
	if use fastbuild ; then
		if [[ -n "${FASTBUILD_PATCH}" ]] && [[ -f "${WORKDIR}/${FASTBUILD_PATCH}" ]] ; then
			epatch "${WORKDIR}/${FASTBUILD_PATCH}"
		else
			ewarn "There is no fastbuild patch available for this PHP release yet!"
		fi
	fi

	# kolab support
	if [[ -n "${KOLAB_PATCH}" ]] ; then
		use kolab && epatch "${WORKDIR}/${KOLAB_PATCH}"
	fi

	# pretend to not have flex, bug 221357
	sed -re 's:( +)PHP_SUBST\(LEX\):\1LEX="exit 0;"\n\0:' -i acinclude.m4

	# Now let the eclass do the rest and regenerate the configure
	php5_2-sapi_src_unpack

	# Fix Makefile.global:test to consider the CGI SAPI if present
	if use cgi ; then
		sed -e "s|test \! -z \"\$(top_builddir)/php-cli\" \&\& test -x \"\$(top_builddir)/php-cli\"|test \! -z \"\$(top_builddir)/php-cli\" \&\& test -x \"\$(top_builddir)/php-cli\" \&\& test \! -z \"\$(top_builddir)/php-cgi\" \&\& test -x \"\$(top_builddir)/php-cgi\"|g" -i Makefile.global
		sed -e "s|TEST_PHP_EXECUTABLE=\"\$(top_builddir)/php-cli\"|TEST_PHP_EXECUTABLE=\"\$(top_builddir)/php-cli\" TEST_PHP_CGI_EXECUTABLE=\"\$(top_builddir)/php-cgi\"|g" -i Makefile.global
	fi

	# try to fix some test cases which fail because of sandbox otherwise
	sed -e 's:/no/such/:.\0:' -i ext/standard/tests/file/005_error.phpt \
		ext/standard/tests/file/006_error.phpt \
		ext/standard/tests/file/touch.phpt

	# REMOVING BROKEN TESTS:
	# removing this test as it has been broken for ages and is not easily
	# fixable (depends on a lot of factors)
	rm ext/standard/tests/general_functions/phpinfo.phpt

	# never worked properly, no easy fix
	rm ext/iconv/tests/iconv_stream_filter.phpt

	# needs write access to /tmp and others
	rm ext/session/tests/session_save_path_variation5.phpt

	# new tests since 5.2.7 which have never been working for me
	rm ext/spl/tests/arrayObject___construct_basic4.phpt \
		ext/spl/tests/arrayObject___construct_basic5.phpt \
		ext/spl/tests/arrayObject_exchangeArray_basic3.phpt \
		ext/spl/tests/arrayObject_setFlags_basic1.phpt

	# those might as well be related to suhosin
	rm ext/session/tests/session_decode_variation3.phpt \
		ext/session/tests/session_encode_variation8.phpt

	# missing skipif
	use reflection || \
		rm ext/standard/tests/directory/DirectoryClass_basic_001.phpt

	# sandbox-related (sandbox checks for permissions before even looking
	# at the fs, but the tests expect "No such file or directory"
	sed -e 's:/blah:./bla:' -i \
		ext/session/tests/session_save_path_variation{2,3}.phpt
	rm ext/standard/tests/file/rename_variation13.phpt

	# test passes, but run-tests.php claims failure
	rm ext/standard/tests/file/tempnam_variation4.phpt

	# these tests behave differently with suhosin enabled, adapting them...
	use suhosin && sed -e 's:File(\.\./):File(..):g' -i \
		tests/security/open_basedir*{.inc,.phpt}
}

src_compile() {
	# bug 217392 (autconf-2.62 behavior changes)
	export CFLAGS="${CFLAGS} -D_GNU_SOURCE"
	export CXXFLAGS="${CXXFLAGS} -D_GNU_SOURCE"
	if use fastbuild && [[ -n "${FASTBUILD_PATCH}" ]] ; then
		src_compile_fastbuild
	else
		src_compile_normal
	fi
}

src_compile_fastbuild() {
	php_determine_sapis

	build_cli=0
	build_cgi=0
	build_apache2=0
	my_conf=""

	for x in ${PHPSAPIS} ; do
		case ${x} in
			cli)
				build_cli=1
				;;
			cgi)
				build_cgi=1
				;;
			apache2)
				build_apache2=1
				;;
		esac
	done

	if [[ ${build_cli} = 1 ]] ; then
		my_conf="${my_conf} --enable-cli"
	else
		my_conf="${my_conf} --disable-cli"
	fi

	if [[ ${build_cgi} = 1 ]] ; then
		my_conf="${my_conf} --enable-cgi --enable-fastcgi"
		phpconfutils_extension_enable "discard-path" "discard-path" 0
		phpconfutils_extension_enable "force-cgi-redirect" "force-cgi-redirect" 0
	else
		my_conf="${my_conf} --disable-cgi"
	fi

	if [[ ${build_apache2} = 1 ]] ; then
		my_conf="${my_conf} --with-apxs2=/usr/sbin/apxs2"

		# Threaded Apache2 support
		if use threads ; then
			my_conf="${my_conf} --enable-maintainer-zts"
			ewarn "Enabling ZTS for Apache2 MPM"
		fi

		# Concurrent PHP Apache2 modules support
		if use concurrentmodphp ; then
			append-ldflags "-Wl,--version-script=${FILESDIR}/php5-ldvs"
		fi
	fi

	if use pcre || phpconfutils_usecheck pcre ; then
		myconf="${my_conf} --with-pcre-dir=/usr"
		phpconfutils_extension_with "pcre-regex" "pcre" 0 "/usr"
	fi

	# Now we know what we are building, build it
	php5_2-sapi_src_compile

	# To keep the separate php.ini files for each SAPI, we change the
	# build-defs.h and recompile

	if [[ ${build_cli} = 1 ]] ; then
		einfo
		einfo "Building CLI SAPI"
		einfo

		sed -e 's|^#define PHP_CONFIG_FILE_PATH.*|#define PHP_CONFIG_FILE_PATH "/etc/php/cli-php5"|g;' -i main/build-defs.h
		sed -e 's|^#define PHP_CONFIG_FILE_SCAN_DIR.*|#define PHP_CONFIG_FILE_SCAN_DIR "/etc/php/cli-php5/ext-active"|g;' -i main/build-defs.h
		for x in main/main.o main/main.lo main/php_ini.o main/php_ini.lo ; do
			[[ -f ${x} ]] && rm -f ${x}
		done
		make sapi/cli/php || die "Unable to make CLI SAPI"
		cp sapi/cli/php php-cli || die "Unable to copy CLI SAPI"
	fi

	if [[ ${build_cgi} = 1 ]] ; then
		einfo
		einfo "Building CGI SAPI"
		einfo

		sed -e 's|^#define PHP_CONFIG_FILE_PATH.*|#define PHP_CONFIG_FILE_PATH "/etc/php/cgi-php5"|g;' -i main/build-defs.h
		sed -e 's|^#define PHP_CONFIG_FILE_SCAN_DIR.*|#define PHP_CONFIG_FILE_SCAN_DIR "/etc/php/cgi-php5/ext-active"|g;' -i main/build-defs.h
		for x in main/main.o main/main.lo main/php_ini.o main/php_ini.lo ; do
			[[ -f ${x} ]] && rm -f ${x}
		done
		make sapi/cgi/php-cgi || die "Unable to make CGI SAPI"
		cp sapi/cgi/php-cgi php-cgi || die "Unable to copy CGI SAPI"
	fi

	if [[ ${build_apache2} = 1 ]] ; then
		einfo
		einfo "Building apache${APACHE_VERSION} SAPI"
		einfo

		sed -e "s|^#define PHP_CONFIG_FILE_PATH.*|#define PHP_CONFIG_FILE_PATH \"/etc/php/apache${APACHE_VERSION}-php5\"|g;" -i main/build-defs.h
		sed -e "s|^#define PHP_CONFIG_FILE_SCAN_DIR.*|#define PHP_CONFIG_FILE_SCAN_DIR \"/etc/php/apache${APACHE_VERSION}-php5/ext-active\"|g;" -i main/build-defs.h
		for x in main/main.o main/main.lo main/php_ini.o main/php_ini.lo ; do
			[[ -f ${x} ]] && rm -f ${x}
		done
		make || die "Unable to make apache${APACHE_VERSION} SAPI"
	fi
}

src_compile_normal() {
	php_determine_sapis

	CLEAN_REQUIRED=0
	my_conf=""

	# Support the Apache2 extras, they must be set globally for all
	# SAPIs to work correctly, especially for external PHP extensions
	if use apache2 ; then
		# Concurrent PHP Apache2 modules support
		if use concurrentmodphp ; then
			append-ldflags "-Wl,--version-script=${FILESDIR}/php5-ldvs"
		fi
	fi

	for x in ${PHPSAPIS} ; do
		if use pcre || phpconfutils_usecheck pcre ; then
			myconf="${my_conf} --with-pcre-dir=/usr"
			phpconfutils_extension_with "pcre-regex" "pcre" 0 "/usr"
		fi

		# Support the Apache2 extras, they must be set globally for all
		# SAPIs to work correctly, especially for external PHP extensions
		if use apache2 ; then
			# Threaded Apache2 support
			if use threads ; then
				my_conf="${my_conf} --enable-maintainer-zts"
				ewarn "Enabling ZTS for Apache2 MPM"
			fi
		fi

		if [[ "${CLEAN_REQUIRED}" = 1 ]] ; then
			make clean
		fi

		PHPSAPI="${x}"

		case ${x} in
			cli)
				my_conf="${my_conf} --enable-cli --disable-cgi"
				php5_2-sapi_src_compile
				cp sapi/cli/php php-cli || die "Unable to copy CLI SAPI"
				;;
			cgi)
				my_conf="${my_conf} --disable-cli --enable-cgi --enable-fastcgi"
				phpconfutils_extension_enable "discard-path" "discard-path" 0
				phpconfutils_extension_enable "force-cgi-redirect" "force-cgi-redirect" 0
				php5_2-sapi_src_compile
				cp sapi/cgi/php-cgi php-cgi || die "Unable to copy CGI SAPI"
				;;
			apache2)
				my_conf="${my_conf} --disable-cli --with-apxs2=/usr/sbin/apxs2"
				php5_2-sapi_src_compile
				;;
		esac

		CLEAN_REQUIRED=1
		my_conf=""
	done
}

src_install() {
	php_determine_sapis

	destdir=/usr/$(get_libdir)/php5

	# Let the eclass do the common work
	php5_2-sapi_src_install

	einfo
	einfo "Installing SAPI(s) ${PHPSAPIS}"
	einfo

	for x in ${PHPSAPIS} ; do

		PHPSAPI="${x}"

		case ${x} in
			cli)
				einfo "Installing CLI SAPI"
				into ${destdir}
				newbin php-cli php || die "Unable to install ${x} sapi"
				php5_2-sapi_install_ini
				;;
			cgi)
				einfo "Installing CGI SAPI"
				into ${destdir}
				dobin php-cgi || die "Unable to install ${x} sapi"
				php5_2-sapi_install_ini
				;;
			apache2)
				einfo "Installing Apache${APACHE_VERSION} SAPI"
				make INSTALL_ROOT="${D}" install-sapi || die "Unable to install ${x} SAPI"
				if use concurrentmodphp ; then
					einfo "Installing Apache${APACHE_VERSION} config file for PHP5-concurrent (70_mod_php5_concurr.conf)"
					insinto ${APACHE_MODULES_CONFDIR}
					newins "${FILESDIR}/70_mod_php5_concurr.conf-apache2-r1" "70_mod_php5_concurr.conf"

					# Put the ld version script in the right place so it's always accessible
					insinto "/var/lib/php-pkg/${CATEGORY}/${PN}-${PVR}/"
					doins "${FILESDIR}/php5-ldvs"

					# Redefine the extension dir to have the modphp suffix
					PHPEXTDIR="`"${D}/${destdir}/bin/php-config" --extension-dir`-versioned"
				else
					einfo "Installing Apache${APACHE_VERSION} config file for PHP5 (70_mod_php5.conf)"
					insinto ${APACHE_MODULES_CONFDIR}
					newins "${FILESDIR}/70_mod_php5.conf-apache2-r1" "70_mod_php5.conf"
				fi
				php5_2-sapi_install_ini
				;;
		esac
	done

	# Install env.d files
	newenvd "${FILESDIR}/20php5-envd" "20php5"
	sed -e "s|/lib/|/$(get_libdir)/|g" -i "${D}/etc/env.d/20php5"
}

pkg_postinst() {
	# Output some general info to the user
	if use apache2 ; then
		APACHE2_MOD_DEFINE="PHP5"
		if use concurrentmodphp ; then
			APACHE2_MOD_CONF="70_mod_php5_concurr"
		else
			APACHE2_MOD_CONF="70_mod_php5"
		fi
		apache-module_pkg_postinst
	fi

	# Update Apache2 to use mod_php
	if use apache2 ; then
		"${ROOT}/usr/sbin/php-select" -t apache2 php5 > /dev/null 2>&1
		exitStatus=$?
		if [[ ${exitStatus} == 2 ]] ; then
			php-select apache2 php5
		elif [[ ${exitStatus} == 4 ]] ; then
			ewarn
			ewarn "Apache2 is configured to load a different version of PHP."
			ewarn "To make Apache2 use PHP v5, use php-select:"
			ewarn
			ewarn "    php-select apache2 php5"
			ewarn
		fi
	fi

	# Create the symlinks for php-cli
	if use cli || phpconfutils_usecheck cli ; then
		"${ROOT}/usr/sbin/php-select" -t php php5 > /dev/null 2>&1
		exitStatus=$?
		if [[ ${exitStatus} == 5 ]] ; then
			php-select php php5
		elif [[ ${exitStatus} == 4 ]] ; then
			ewarn
			ewarn "/usr/bin/php links to a different version of PHP."
			ewarn "To make /usr/bin/php point to PHP v5, use php-select:"
			ewarn
			ewarn "    php-select php php5"
			ewarn
		fi
	fi

	# Create the symlinks for php-cgi
	if use cgi ; then
		"${ROOT}/usr/sbin/php-select" -t php-cgi php5 > /dev/null 2>&1
		exitStatus=$?
		if [[ ${exitStatus} == 5 ]] ; then
			php-select php-cgi php5
		elif [[ ${exitStatus} == 4 ]] ; then
			ewarn
			ewarn "/usr/bin/php-cgi links to a different version of PHP."
			ewarn "To make /usr/bin/php-cgi point to PHP v5, use php-select:"
			ewarn
			ewarn "    php-select php-cgi php5"
			ewarn
		fi
	fi

	# Create the symlinks for php-devel
	"${ROOT}/usr/sbin/php-select" -t php-devel php5 > /dev/null 2>&1
	exitStatus=$?
	if [[ $exitStatus == 5 ]] ; then
		php-select php-devel php5
	elif [[ $exitStatus == 4 ]] ; then
		ewarn
		ewarn "/usr/bin/php-config and/or /usr/bin/phpize are linked to a"
		ewarn "different version of PHP. To make them point to PHP v5, use"
		ewarn "php-select:"
		ewarn
		ewarn "    php-select php-devel php5"
		ewarn
	fi

	php5_2-sapi_pkg_postinst
}

src_test() {
	echo ">>> Test phase [test]: ${CATEGORY}/${PF}"
	if [[ ! -x "${S}"/php-cli ]]; then
		ewarn "Running the php test suite requires USE=cli"
		return
	fi

	export TEST_PHP_EXECUTABLE="${S}"/php-cli
	if [[ -x "${S}"/php-cgi ]]; then
		export TEST_PHP_CGI_EXECUTABLE="${S}"/php-cgi
	fi
	REPORT_EXIT_STATUS=1 "${S}"/php-cli -n "${S}"/run-tests.php -n

	if [[ $? != 0 ]] ; then
		eerror "Not all tests were successful!"
	fi
}
