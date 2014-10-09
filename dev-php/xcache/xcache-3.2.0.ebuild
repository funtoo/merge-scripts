# Distributed under the terms of the GNU General Public License v2

EAPI="5"
PHP_EXT_NAME="xcache"
PHP_EXT_INI="yes"
PHPSAPILIST="apache2 cgi cli fpm"

USE_PHP="php5-3 php5-4 php5-5 php5-6"
inherit php-ext-source-r2 confutils

DESCRIPTION="A fast and stable PHP opcode cacher"
HOMEPAGE="http://xcache.lighttpd.net/"
SRC_URI="http://xcache.lighttpd.net/pub/Releases/${PV}/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="*"
IUSE=""

# make test would just run php's test and as such need the full php source
RESTRICT="test"

DEPEND="!dev-php/eaccelerator !dev-php/pecl-apc"
RDEPEND="${DEPEND}"

src_configure() {

	my_conf="--enable-xcache=shared   \
			--enable-xcache-constant  \
			--enable-xcache-optimizer \
			--enable-xcache-coverager \
			--enable-xcache-assembler \
			--enable-xcache-encoder   \
			--enable-xcache-decoder"

	php-ext-source-r2_src_configure
}

src_install() {
	php-ext-source-r2_src_install
	php-ext-source-r2_addtoinifiles xcache.admin.enable_auth "On"
	php-ext-source-r2_addtoinifiles xcache.admin.user "admin"
	php-ext-source-r2_addtoinifiles xcache.admin.pass ""
	php-ext-source-r2_addtoinifiles xcache.cacher "On"
	php-ext-source-r2_addtoinifiles xcache.size "128M"
	php-ext-source-r2_addtoinifiles xcache.count "2"
	php-ext-source-r2_addtoinifiles xcache.slots "8k"
	php-ext-source-r2_addtoinifiles xcache.ttl "0"
	php-ext-source-r2_addtoinifiles xcache.gc_interval "0"
	php-ext-source-r2_addtoinifiles xcache.var_size "8M"
	php-ext-source-r2_addtoinifiles xcache.var_count "1"
	php-ext-source-r2_addtoinifiles xcache.var_slots "8K"
	php-ext-source-r2_addtoinifiles xcache.var_ttl "0"
	php-ext-source-r2_addtoinifiles xcache.var_maxttl "0"
	php-ext-source-r2_addtoinifiles xcache.var_gc_interval "600"
	php-ext-source-r2_addtoinifiles xcache.readonly_protection "Off"
	php-ext-source-r2_addtoinifiles xcache.mmap_path "/dev/zero"
	php-ext-source-r2_addtoinifiles xcache.coverager "Off"
	php-ext-source-r2_addtoinifiles xcache.coveragedump_directory ""
	php-ext-source-r2_addtoinifiles xcache.optimizer "Off"
	dodoc AUTHORS ChangeLog NEWS README THANKS

	insinto "${PHP_EXT_SHARED_DIR}"
	doins lib/Decompiler.class.php
	insinto "${PHP_EXT_SHARED_DIR}"
	doins -r htdocs
}

pkg_postinst() {
	elog "lib/Decompiler.class.php, and the htdocs/ directory shipped with this"
	elog "release were installed into ${PHP_EXT_SHARED_DIR}."
}
