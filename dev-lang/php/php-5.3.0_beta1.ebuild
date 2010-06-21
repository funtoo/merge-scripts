# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils autotools versionator

MY_PV=$(replace_version_separator 3 '')

DESCRIPTION="A widely-used general-purpose scripting language."
HOMEPAGE="http://qa.php.net/"
SRC_URI="http://downloads.php.net/johannes/${PN}-${MY_PV}.tar.bz2"

LICENSE="PHP-3.01"
KEYWORDS="~x86 ~amd64"
SLOT="5"

IUSE="+cli +cgi -short-tags -ipv6 +libxml -ssl +sqlite3 +zlib +bz2 -curl +dom -exif -ftp +json +mbstring +mcrypt +mysql -pear +spawn-fcgi"

FEATURES="strict sandbox collision-protect"

DEPEND="
    =sys-devel/libtool-1.5.26
    libxml? ( dev-libs/libxml2 )
    ssl? ( >=dev-libs/openssl-0.9.6 )
    sqlite3? ( >=dev-db/sqlite-3.0.0 )
    zlib? ( >=sys-libs/zlib-1.0.9 )
    bz2? ( app-arch/bzip2 )
    curl? ( net-misc/curl )
    mysql? ( || ( dev-db/mysql dev-db/mysql-community ) )"

RDEPEND="${DEPEND}"

S="${PN}-${MY_PV}"

MY_DIRCONF="/etc/php"

src_unpack() {
    unpack ${A}
    cd "${S}"

    eautoreconf || die "eautoreconf failed"
}

src_compile() {
    local myconf

    ## SAPI modules ...
    if ! use cli ; then
        myconf="${myconf} --disable-cli"
    fi

    if ! use cgi ; then
        myconf="${myconf} --disable-cgi"
    fi

    ## General settings ...
    if ! use short-tags ; then
        myconf="${myconf} --disable-short-tags "
    fi

    if ! use ipv6 ; then
        myconf="${myconf} --disable-ipv6"
    fi

    ## Extensions ...
    if ! use libxml ; then
        myconf="${myconf} --disable-libxml"
    fi

    if use ssl ; then
        myconf="${myconf} --with-openssl"
    fi

    if ! use sqlite3 ; then
        myconf="${myconf} --without-sqlite3"
    fi

    if use zlib ; then
        myconf="${myconf} --with-zlib"
    fi

    if use bz2 ; then
        myconf="${myconf} --with-bz2"
    fi

    if use curl ; then
        myconf="${myconf} --with-curl --with-curlwrappers"
    fi

    if ! use dom ; then
        myconf="${myconf} --disable-dom"
    fi

    if use exif ; then
        myconf="${myconf} --enable-exif"
    fi

    if use ftp ; then
        myconf="${myconf} --enable-ftp"
    fi

    if ! use json ; then
        myconf="${myconf} --disable-json"
    fi

    if use mbstring ; then
        myconf="${myconf} --enable-mbstring"
    fi

    if use mcrypt ; then
        myconf="${myconf} --with-mcrypt"
    fi

    if use mysql ; then
        myconf="${myconf} --with-mysql --with-mysql-sock=/var/run/mysqld/mysqld.sock"
    fi

    ## Pear ...
    if ! use pear ; then
        myconf="${myconf} --without-pear"
    fi

    cd "${S}"
    econf --with-config-file-path=${MY_DIRCONF} ${myconf} || die "configure failed"

    emake || die "make failed"
}

src_test() {
    make check || die "make check failed"
}

src_install() {
    cd "${S}"

    #emake DESTDIR="${D}" install || die "install failed"
    make INSTALL_ROOT="${D}" install || die "make install failed"

    dodir "${ROOT}${MY_DIRCONF}"
    insinto "${ROOT}${MY_DIRCONF}"
    doins *.ini-*
    newins php.ini-recommended php.ini

    if use spawn-fcgi ; then
        newconfd "${FILESDIR}/${PV}/conf.d/phpd" phpd
        newinitd "${FILESDIR}/${PV}/init.d/phpd" phpd
    fi
}

pkg_preinst() {
    enewgroup php
    enewuser php -1 -1 -1 php
}

pkg_postinst() {
    # Currently too lazy to track down the where this comes from (might be pear).
    rm -rf /.registry
    rm -rf /.lock
    rm -rf /.filemap
    rm -rf /.depdblock
    rm -rf /.depdb
    rm -rf /.channels

    elog ""
    elog "Don't forget to edit the ${MY_DIRCONF}/php.ini file!"
}
