# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-servers/apache/apache-2.2.15.ebuild,v 1.10 2010/04/06 15:30:23 abcd Exp $

# latest gentoo apache files
GENTOO_PATCHSTAMP="20100307"
GENTOO_DEVELOPER="hollow"

# IUSE/USE_EXPAND magic
IUSE_MPMS_FORK="itk peruser prefork"
IUSE_MPMS_THREAD="event worker"

IUSE_MODULES="actions alias asis auth_basic auth_digest authn_alias authn_anon
authn_dbd authn_dbm authn_default authn_file authz_dbm authz_default
authz_groupfile authz_host authz_owner authz_user autoindex cache cern_meta
charset_lite dav dav_fs dav_lock dbd deflate dir disk_cache dumpio env expires
ext_filter file_cache filter headers ident imagemap include info log_config
log_forensic logio mem_cache mime mime_magic negotiation proxy proxy_ajp
proxy_balancer proxy_connect proxy_ftp proxy_http rewrite setenvif speling
status substitute unique_id userdir usertrack version vhost_alias"

# inter-module dependencies
# TODO: this may still be incomplete
MODULE_DEPENDS="
	dav_fs:dav
	dav_lock:dav
	deflate:filter
	disk_cache:cache
	ext_filter:filter
	file_cache:cache
	log_forensic:log_config
	logio:log_config
	mem_cache:cache
	mime_magic:mime
	proxy_ajp:proxy
	proxy_balancer:proxy
	proxy_connect:proxy
	proxy_ftp:proxy
	proxy_http:proxy
	substitute:filter
"

# module<->define mappings
MODULE_DEFINES="
	auth_digest:AUTH_DIGEST
	authnz_ldap:AUTHNZ_LDAP
	cache:CACHE
	dav:DAV
	dav_fs:DAV
	dav_lock:DAV
	disk_cache:CACHE
	file_cache:CACHE
	info:INFO
	ldap:LDAP
	mem_cache:CACHE
	proxy:PROXY
	proxy_ajp:PROXY
	proxy_balancer:PROXY
	proxy_connect:PROXY
	proxy_ftp:PROXY
	proxy_http:PROXY
	ssl:SSL
	status:STATUS
	suexec:SUEXEC
	userdir:USERDIR
"

# critical modules for the default config
MODULE_CRITICAL="
	authz_host
	dir
	mime
"

inherit apache-2

DESCRIPTION="The Apache Web Server."
HOMEPAGE="http://httpd.apache.org/"

# some helper scripts are Apache-1.1, thus both are here
LICENSE="Apache-2.0 Apache-1.1"
SLOT="2"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE=""

DEPEND="${DEPEND}
	>=dev-libs/openssl-0.9.8m
	apache2_modules_deflate? ( sys-libs/zlib )"

RDEPEND="${RDEPEND}
	>=dev-libs/openssl-0.9.8m
	apache2_modules_mime? ( app-misc/mime-types )"
