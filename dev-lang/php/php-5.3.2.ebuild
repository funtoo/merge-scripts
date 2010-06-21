# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/php/php-5.3.2.ebuild,v 1.8 2010/06/14 17:03:23 mabi Exp $

EAPI=2

PHPCONFUTILS_MISSING_DEPS="adabas birdstep db2 dbmaker empress empress-bcs esoob interbase oci8 sapdb solid sybase-ct"

inherit eutils autotools flag-o-matic versionator depend.apache apache-module db-use phpconfutils php-common-r1 libtool

PHP_PATCHSET=""
SUHOSIN_VERSION="$PV-0.9.9.1"
EXPECTED_TEST_FAILURES=""

KEYWORDS="~amd64 ~x86"

function php_get_uri ()
{
	case "${1}" in
		"php-pre")
			echo "http://downloads.php.net/johannes/${2}"
		;;
		"php")
			echo "http://www.php.net/distributions/${2}"
		;;
		"suhosin")
			echo "http://download.suhosin.org/${2}"
		;;
		"gentoo")
			echo "mirror://gentoo/${2}"
		;;
		*)
			die "unhandled case in php_get_uri"
		;;
	esac
}

PHP_MV="$(get_major_version)"

# alias, so we can handle different types of releases (finals, rcs, alphas,
# betas, ...) w/o changing the whole ebuild
PHP_PV="${PV}"
PHP_RELEASE="php"
PHP_P="${PN}-${PHP_PV}"
PHP_SRC_URI="$(php_get_uri "${PHP_RELEASE}" "${PHP_P}.tar.bz2")"

PHP_PATCHSET="${PHP_PATCHSET:-${PR/r/}}"
PHP_PATCHSET_URI="
	$(php_get_uri gentoo "php-patchset-${PV}-r${PHP_PATCHSET}.tar.bz2")"

if [[ ${SUHOSIN_VERSION} == *-gentoo ]]; then
	# in some cases we use our own suhosin patch (very recent version,
	# patch conflicts, etc.)
	SUHOSIN_TYPE="gentoo"
else
	SUHOSIN_TYPE="suhosin"
fi

SUHOSIN_PATCH="suhosin-patch-${SUHOSIN_VERSION}.patch"
SUHOSIN_URI="$(php_get_uri ${SUHOSIN_TYPE} ${SUHOSIN_PATCH}.gz )"

SRC_URI="
	${PHP_SRC_URI}
	${PHP_PATCHSET_URI}
	suhosin? ( ${SUHOSIN_URI} )"

DESCRIPTION="The PHP language runtime engine: CLI, CGI, Apache2 and embed SAPIs."
HOMEPAGE="http://php.net/"
LICENSE="PHP-3"

# We can build the following SAPIs in the given order
SAPIS="cli cgi embed apache2"

# Gentoo-specific, common features
IUSE="kolab"

# SAPIs and SAPI-specific USE flags:
IUSE="${IUSE}
	+${SAPIS}
	concurrentmodphp threads"

IUSE="${IUSE} adabas bcmath berkdb birdstep bzip2 calendar cdb cjk
	crypt +ctype curl curlwrappers db2 dbmaker debug doc empress
	empress-bcs enchant esoob exif frontbase +fileinfo +filter firebird
	flatfile ftp gd gd-external gdbm gmp +hash +iconv imap inifile
	interbase intl iodbc ipv6 +json kerberos ldap ldap-sasl libedit
	mssql mysql mysqlnd mysqli nls oci8
	oci8-instant-client odbc pcntl pdo +phar pic +posix postgres qdbm
	readline recode sapdb +session sharedext sharedmem
	+simplexml snmp soap sockets solid spell sqlite sqlite3 ssl suhosin
	sybase-ct sysvipc tidy +tokenizer truetype unicode wddx
	xml xmlreader xmlwriter xmlrpc xpm xsl zip zlib"

DEPEND="app-admin/php-toolkit
	>=dev-libs/libpcre-7.9[unicode]
	adabas? ( >=dev-db/unixODBC-1.8.13 )
	apache2? ( www-servers/apache[threads=] )
	berkdb? ( =sys-libs/db-4* )
	birdstep? ( >=dev-db/unixODBC-1.8.13 )
	bzip2? ( app-arch/bzip2 )
	cdb? ( || ( dev-db/cdb dev-db/tinycdb ) )
	cjk? ( !gd? ( !gd-external? (
		>=media-libs/jpeg-6b
		media-libs/libpng
		sys-libs/zlib
	) ) )
	crypt? ( >=dev-libs/libmcrypt-2.4 )
	curl? ( >=net-misc/curl-7.10.5 )
	db2? ( >=dev-db/unixODBC-1.8.13 )
	dbmaker? ( >=dev-db/unixODBC-1.8.13 )
	empress? ( >=dev-db/unixODBC-1.8.13 )
	empress-bcs? ( >=dev-db/unixODBC-1.8.13 )
	enchant? ( app-text/enchant )
	esoob? ( >=dev-db/unixODBC-1.8.13 )
	exif? ( !gd? ( !gd-external? (
		>=media-libs/jpeg-6b
		media-libs/libpng
		sys-libs/zlib
	) ) )
	firebird? ( dev-db/firebird )
	gd? ( >=media-libs/jpeg-6b media-libs/libpng sys-libs/zlib )
	gd-external? ( media-libs/gd )
	gdbm? ( >=sys-libs/gdbm-1.8.0 )
	gmp? ( >=dev-libs/gmp-4.1.2 )
	iconv? ( virtual/libiconv )
	imap? (
		virtual/imap-c-client[ssl=]
		virtual/imap-c-client[kolab=]
	)
	intl? ( dev-libs/icu )
	iodbc? ( dev-db/libiodbc )
	kerberos? ( virtual/krb5 )
	kolab? ( >=net-libs/c-client-2004g-r1 )
	ldap? ( !oci8? ( >=net-nds/openldap-1.2.11 ) )
	ldap-sasl? ( !oci8? ( dev-libs/cyrus-sasl >=net-nds/openldap-1.2.11 ) )
	libedit? ( || ( sys-freebsd/freebsd-lib dev-libs/libedit ) )
	mssql? ( dev-db/freetds )
	!mysqlnd? (
		mysql? ( virtual/mysql )
		mysqli? ( >=virtual/mysql-4.1 )
	)
	nls? ( sys-devel/gettext )
	oci8-instant-client? ( dev-db/oracle-instantclient-basic )
	odbc? ( >=dev-db/unixODBC-1.8.13 )
	postgres? (
		|| (
			>=dev-db/postgresql-base-7.1[threads=]
			(
				|| (
					<dev-db/libpq-8
					>=dev-db/libpq-8[threads=]
				)
			)
		)
	)
	qdbm? ( dev-db/qdbm )
	readline? ( sys-libs/readline )
	recode? ( app-text/recode )
	sapdb? ( >=dev-db/unixODBC-1.8.13 )
	sharedmem? ( dev-libs/mm )
	simplexml? ( >=dev-libs/libxml2-2.6.8 )
	snmp? ( >=net-analyzer/net-snmp-5.2 )
	soap? ( >=dev-libs/libxml2-2.6.8 )
	solid? ( >=dev-db/unixODBC-1.8.13 )
	spell? ( >=app-text/aspell-0.50 )
	sqlite? ( =dev-db/sqlite-2* pdo? ( =dev-db/sqlite-3* ) )
	sqlite3? ( =dev-db/sqlite-3* )
	ssl? ( >=dev-libs/openssl-0.9.7 )
	tidy? ( app-text/htmltidy )
	truetype? (
		=media-libs/freetype-2*
		>=media-libs/t1lib-5.0.0
		!gd? ( !gd-external? (
			>=media-libs/jpeg-6b media-libs/libpng sys-libs/zlib ) )
	)
	unicode? ( dev-libs/oniguruma )
	wddx? ( >=dev-libs/libxml2-2.6.8 )
	xml? ( >=dev-libs/libxml2-2.6.8 )
	xmlrpc? ( >=dev-libs/libxml2-2.6.8 virtual/libiconv )
	xmlreader? ( >=dev-libs/libxml2-2.6.8 )
	xmlwriter? ( >=dev-libs/libxml2-2.6.8 )
	xpm? (
		x11-libs/libXpm
		>=media-libs/jpeg-6b
		media-libs/libpng sys-libs/zlib
	)
	xsl? ( dev-libs/libxslt >=dev-libs/libxml2-2.6.8 )
	zip? ( sys-libs/zlib )
	zlib? ( sys-libs/zlib )
	virtual/mta
"

php="=${CATEGORY}/${PF}"
RDEPEND="${DEPEND}
	truetype? ( || ( $php[gd] $php[gd-external] ) )
	cjk? ( || ( $php[gd] $php[gd-external] ) )
	exif? ( || ( $php[gd] $php[gd-external] ) )

	xpm? ( $php[gd] )
	gd? ( $php[zlib,-gd-external] )
	gd-external? ( $php[-gd] )
	simplexml? ( $php[xml] )
	soap? ( $php[xml] )
	wddx? ( $php[xml] )
	xmlrpc? ( || ( $php[xml] $php[iconv] ) )
	xmlreader? ( $php[xml] )
	xsl? ( $php[xml] )
	ldap-sasl? ( $php[ldap,-oci8] )
	suhosin? ( $php[unicode] )
	adabas? ( $php[odbc] )
	birdstep? ( $php[odbc] )
	dbmaker? ( $php[odbc] )
	empress-bcs? ( $php[empress] )
	empress? ( $php[odbc] )
	esoob? ( $php[odbc] )
	db2? ( $php[odbc] )
	iodbc? ( $php[iodbc] )
	sapdb? ( $php[odbc] )
	solid? ( $php[odbc] )
	kolab? ( $php[imap] )
	phar? ( $php[hash] )
	mysqlnd? ( || (
		$php[mysql]
		$php[mysqli]
		$php[pdo]
	) )

	oci8? ( $php[-oci8-instant-client,-ldap-sasl] )
	oci8-instant-client? ( $php[-oci8] )

	qdbm? ( $php[-gdbm] )
	readline? ( $php[-libedit] )
	recode? ( $php[-imap,-mysql,-mysqli] )
	firebird? ( $php[-interbase] )
	sharedmem? ( $php[-threads] )

	!cli? ( !cgi? ( !apache2? ( !embed? ( $php[cli] ) ) ) )

	enchant? ( !dev-php${PHP_MV}/pecl-enchant )
	fileinfo? ( !dev-php${PHP_MV}/pecl-fileinfo )
	filter? ( !dev-php${PHP_MV}/pecl-filter )
	json? ( !dev-php${PHP_MV}/pecl-json )
	phar? ( !dev-php${PHP_MV}/pecl-phar )
	zip? ( !dev-php${PHP_MV}/pecl-zip )"

DEPEND="${DEPEND}
	sys-devel/flex
	>=sys-devel/m4-1.4.3
	>=sys-devel/libtool-1.5.18"

# They are in PDEPEND because we need PHP installed first!
PDEPEND="doc? ( app-doc/php-docs )
	suhosin? ( dev-php${PHP_MV}/suhosin )"

# Portage doesn't support setting PROVIDE based on the USE flags that
# have been enabled, so we have to PROVIDE everything for now and hope
# for the best
PROVIDE="virtual/php virtual/httpd-php"

SLOT="${PHP_MV}"
S="${WORKDIR}/${PHP_P}"

PHP_INI_FILE="php.ini"
PHP_INI_UPSTREAM="php.ini-production"

want_apache

# eblit-core
# Usage: <function> [version] [eval]
# Main eblit engine
eblit-core() {
	[[ -z $FILESDIR ]] && FILESDIR="$(dirname $EBUILD)/files"
	local e v func=$1 ver=$2 eval_=$3
	for v in ${ver:+-}${ver} -${PVR} -${PV} "" ; do
		e="${FILESDIR}/eblits/${func}${v}.eblit"
		if [[ -e ${e} ]] ; then
			. "${e}"
			[[ ${eval_} == 1 ]] && eval "${func}() { eblit-run ${func} ${ver} ; }"
			return 0
		fi
	done
	return 1
}

# eblit-include
# Usage: [--skip] <function> [version]
# Includes an "eblit" -- a chunk of common code among ebuilds in a given
# package so that its functions can be sourced and utilized within the
# ebuild.
eblit-include() {
	local skipable=false r=0
	[[ $1 == "--skip" ]] && skipable=true && shift
	[[ $1 == pkg_* ]] && skipable=true

	[[ -z $1 ]] && die "Usage: eblit-include <function> [version]"
	eblit-core $1 $2
	r="$?"
	${skipable} && return 0
	[[ "$r" -gt "0" ]] && die "Could not locate requested eblit '$1' in ${FILESDIR}/eblits/"
}

# eblit-run-maybe
# Usage: <function>
# Runs a function if it is defined in an eblit
eblit-run-maybe() {
	[[ $(type -t "$@") == "function" ]] && "$@"
}

# eblit-run
# Usage: <function> [version]
# Runs a function defined in an eblit
eblit-run() {
	eblit-include --skip common "${*:2}"
	eblit-include "$@"
	eblit-run-maybe eblit-$1-pre
	eblit-${PN}-$1
	eblit-run-maybe eblit-$1-post
}

# eblit-pkg
# Usage: <phase> [version]
# Includes the given functions AND evals them so they're included in the binpkgs
eblit-pkg() {
	[[ -z $1 ]] && die "Usage: eblit-pkg <phase> [version]"
	eblit-core $1 $2 1
}

eblit-pkg pkg_setup v1

src_prepare() { eblit-run src_prepare v1 ; }
src_configure() { eblit-run src_configure v1 ; }
src_compile() { eblit-run src_compile v1 ; }
src_install() { eblit-run src_install v1 ; }
src_test() { eblit-run src_test v1 ; }

eblit-pkg pkg_postinst v1
