# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/mysql.eclass,v 1.146 2010/05/13 19:45:47 robbat2 Exp $

# @ECLASS: mysql.eclass
# @MAINTAINER:
# Author: Francesco Riosa (Retired) <vivo@gentoo.org>
# Maintainers: MySQL Team <mysql-bugs@gentoo.org>
#		- Luca Longinotti <chtekk@gentoo.org>
#		- Robin H. Johnson <robbat2@gentoo.org>
# @BLURB: This eclass provides most of the functions for mysql ebuilds
# @DESCRIPTION:
# The mysql.eclass provides almost all the code to build the mysql ebuilds
# including the src_unpack, src_prepare, src_configure, src_compile,
# scr_install, pkg_preinst, pkg_postinst, pkg_config and pkg_postrm
# phase hooks.

WANT_AUTOCONF="latest"
WANT_AUTOMAKE="latest"

inherit eutils flag-o-matic gnuconfig autotools mysql_fx versionator toolchain-funcs

# Shorten the path because the socket path length must be shorter than 107 chars
# and we will run a mysql server during test phase
S="${WORKDIR}/mysql"

[[ "${MY_EXTRAS_VER}" == "latest" ]] && MY_EXTRAS_VER="20090228-0714Z"
if [[ "${MY_EXTRAS_VER}" == "live" ]]; then
	EGIT_PROJECT=mysql-extras
	EGIT_REPO_URI="git://git.overlays.gentoo.org/proj/mysql-extras.git"
	inherit git
fi

case "${EAPI:-0}" in
	2)
		EXPORT_FUNCTIONS pkg_setup \
					src_unpack src_prepare \
					src_configure src_compile \
					src_install \
					pkg_preinst pkg_postinst \
					pkg_config pkg_postrm
		IUSE_DEFAULT_ON='+'
		;;
	0 | 1)
		EXPORT_FUNCTIONS pkg_setup \
					src_unpack \
					src_compile \
					src_install \
					pkg_preinst pkg_postinst \
					pkg_config pkg_postrm
		;;
	*)
		die "Unsupported EAPI: ${EAPI}" ;;
esac


# @ECLASS-VARIABLE: MYSQL_PV_MAJOR
# @DESCRIPTION:
# Upstream MySQL considers the first two parts of the version number to be the
# major version. Upgrades that change major version should always run
# mysql_upgrade.
MYSQL_PV_MAJOR="$(get_version_component_range 1-2 ${PV})"

# @ECLASS-VARIABLE: MYSQL_VERSION_ID
# @DESCRIPTION:
# MYSQL_VERSION_ID will be:
# major * 10e6 + minor * 10e4 + micro * 10e2 + gentoo revision number, all [0..99]
# This is an important part, because many of the choices the MySQL ebuild will do
# depend on this variable.
# In particular, the code below transforms a $PVR like "5.0.18-r3" in "5001803"
# We also strip off upstream's trailing letter that they use to respin tarballs

MYSQL_VERSION_ID=""
tpv="${PV%[a-z]}"
tpv=( ${tpv//[-._]/ } ) ; tpv[3]="${PVR:${#PV}}" ; tpv[3]="${tpv[3]##*-r}"
for vatom in 0 1 2 3 ; do
	# pad to length 2
	tpv[${vatom}]="00${tpv[${vatom}]}"
	MYSQL_VERSION_ID="${MYSQL_VERSION_ID}${tpv[${vatom}]:0-2}"
done
# strip leading "0" (otherwise it's considered an octal number by BASH)
MYSQL_VERSION_ID=${MYSQL_VERSION_ID##"0"}

# @ECLASS-VARIABLE: MYSQL_COMMUNITY_FEATURES
# @DESCRIPTION:
# Specifiy if community features are available. Possible values are 1 (yes)
# and 0 (no).
# Community features are available in mysql-community
# AND in the re-merged mysql-5.0.82 and newer
if [ "${PN}" == "mysql-community" -o "${PN}" == "mariadb" ]; then
	MYSQL_COMMUNITY_FEATURES=1
elif [ "${PV#5.0}" != "${PV}" ] && mysql_version_is_at_least "5.0.82"; then
	MYSQL_COMMUNITY_FEATURES=1
elif [ "${PV#5.1}" != "${PV}" ] && mysql_version_is_at_least "5.1.28"; then
	MYSQL_COMMUNITY_FEATURES=1
elif [ "${PV#5.4}" != "${PV}" ] ; then
	MYSQL_COMMUNITY_FEATURES=1
elif [ "${PV#5.5}" != "${PV}" ] ; then
	MYSQL_COMMUNITY_FEATURES=1
elif [ "${PV#6.0}" != "${PV}" ] ; then
	MYSQL_COMMUNITY_FEATURES=1
else
	MYSQL_COMMUNITY_FEATURES=0
fi

# @ECLASS-VARIABLE: XTRADB_VER
# @DESCRIPTION:
# Version of the XTRADB storage engine
XTRADB_VER="${XTRADB_VER}"

# @ECLASS-VARIABLE: PERCONA_VER
# @DESCRIPTION:
# Designation by PERCONA for a MySQL version to apply an XTRADB release
PERCONA_VER="${PERCONA_VER}"

# Be warned, *DEPEND are version-dependant
# These are used for both runtime and compiletime
DEPEND="ssl? ( >=dev-libs/openssl-0.9.6d )
		userland_GNU? ( sys-process/procps )
		>=sys-apps/sed-4
		>=sys-apps/texinfo-4.7-r1
		>=sys-libs/readline-4.1
		>=sys-libs/zlib-1.2.3"

[[ "${PN}" == "mariadb" ]] \
&& DEPEND="${DEPEND} libevent? ( >=dev-libs/libevent-1.4 )"

# Having different flavours at the same time is not a good idea
for i in "mysql" "mysql-community" "mariadb" ; do
	[[ "${i}" == ${PN} ]] ||
	DEPEND="${DEPEND} !dev-db/${i}"
done

RDEPEND="${DEPEND}
		!minimal? ( dev-db/mysql-init-scripts )
		selinux? ( sec-policy/selinux-mysql )"

# compile-time-only
mysql_version_is_at_least "5.1" \
|| DEPEND="${DEPEND} berkdb? ( sys-apps/ed )"

# compile-time-only
mysql_version_is_at_least "5.1.12" \
&& DEPEND="${DEPEND} >=dev-util/cmake-2.4.3"

# dev-perl/DBD-mysql is needed by some scripts installed by MySQL
PDEPEND="perl? ( >=dev-perl/DBD-mysql-2.9004 )"

# For other stuff to bring us in
PDEPEND="${PDEPEND} =virtual/mysql-${MYSQL_PV_MAJOR}"

# Work out the default SERVER_URI correctly
if [ -z "${SERVER_URI}" ]; then
	[ -z "${MY_PV}" ] && MY_PV="${PV//_/-}"
	if [ "${PN}" == "mariadb" ]; then
		MARIA_FULL_PV="$(replace_version_separator 3 '-' ${PV})"
		MARIA_FULL_P="${PN}-${MARIA_FULL_PV}"
		SERVER_URI="
		http://ftp.rediris.es/mirror/MariaDB/${MARIA_FULL_P}/kvm-tarbake-jaunty-x86/${MARIA_FULL_P}.tar.gz
		http://maria.llarian.net/download/${MARIA_FULL_P}/kvm-tarbake-jaunty-x86/${MARIA_FULL_P}.tar.gz
		http://launchpad.net/maria/${MYSQL_PV_MAJOR}/ongoing/+download/${MARIA_FULL_P}.tar.gz
		"
	# The community build is on the mirrors
	elif [ "${MYSQL_COMMUNITY_FEATURES}" == "1" ]; then
		SERVER_URI="mirror://mysql/Downloads/MySQL-${PV%.*}/mysql-${MY_PV}.tar.gz"
	# The (old) enterprise source is on the primary site only
	elif [ "${PN}" == "mysql" ]; then
		SERVER_URI="ftp://ftp.mysql.com/pub/mysql/src/mysql-${MY_PV}.tar.gz"
	fi
fi

# Define correct SRC_URIs
SRC_URI="${SERVER_URI}"

# Gentoo patches to MySQL
[[ ${MY_EXTRAS_VER} != live ]] \
&& SRC_URI="${SRC_URI}
		mirror://gentoo/mysql-extras-${MY_EXTRAS_VER}.tar.bz2
		http://g3nt8.org/patches/mysql-extras-${MY_EXTRAS_VER}.tar.bz2
		http://dev.gentoo.org/~robbat2/distfiles/mysql-extras-${MY_EXTRAS_VER}.tar.bz2"

DESCRIPTION="A fast, multi-threaded, multi-user SQL database server."
HOMEPAGE="http://www.mysql.com/"
if [[ "${PN}" == "mariadb" ]]; then
	HOMEPAGE="http://askmonty.org/"
	DESCRIPTION="MariaDB is a MySQL fork with 3rd-party patches and additional storage engines merged."
fi
if [[ "${PN}" == "mysql-community" ]]; then
	DESCRIPTION="${DESCRIPTION} (obsolete, move to dev-db/mysql)"
fi
LICENSE="GPL-2"
SLOT="0"
IUSE="big-tables debug embedded minimal ${IUSE_DEFAULT_ON}perl selinux ssl static test"

mysql_version_is_at_least "4.1" \
&& IUSE="${IUSE} latin1"

mysql_version_is_at_least "4.1.3" \
&& IUSE="${IUSE} cluster extraengine"

mysql_version_is_at_least "5.0" \
|| IUSE="${IUSE} raid"

mysql_version_is_at_least "5.0.18" \
&& IUSE="${IUSE} max-idx-128"

mysql_version_is_at_least "5.1" \
|| IUSE="${IUSE} berkdb"

[ "${MYSQL_COMMUNITY_FEATURES}" == "1" ] \
&& IUSE="${IUSE} ${IUSE_DEFAULT_ON}community profiling"

[[ "${PN}" == "mariadb" ]] \
&& IUSE="${IUSE} libevent"

# MariaDB has integrated PBXT
# PBXT_VERSION means that we have a PBXT patch for this PV
# PBXT was only introduced after 5.1.12
pbxt_patch_available() {
	[[ "${PN}" != "mariadb" ]] \
	&& mysql_version_is_at_least "5.1.12" \
	&& [[ -n "${PBXT_VERSION}" ]]
	return $?
}

pbxt_available() {
	pbxt_patch_available || [[ "${PN}" == "mariadb" ]]
	return $?
}

# Get the percona tarball if XTRADB_VER and PERCONA_VER are both set
# MariaDB has integrated XtraDB
# XTRADB_VERS means that we have a XTRADB patch for this PV
# XTRADB was only introduced after 5.1.26
xtradb_patch_available() {
	[[ "${PN}" != "mariadb" ]] \
	&& mysql_version_is_at_least "5.1.26" \
	&& [[ -n "${XTRADB_VER}" && -n "${PERCONA_VER}" ]]
	return $?
}


pbxt_patch_available \
&& PBXT_P="pbxt-${PBXT_VERSION}" \
&& PBXT_SRC_URI="http://www.primebase.org/download/${PBXT_P}.tar.gz mirror://sourceforge/pbxt/${PBXT_P}.tar.gz" \
&& SRC_URI="${SRC_URI} pbxt? ( ${PBXT_SRC_URI} )" \

# PBXT_NEWSTYLE means pbxt is in storage/ and gets enabled as other plugins
# vs. built outside the dir
pbxt_available \
&& IUSE="${IUSE} pbxt" \
&& mysql_version_is_at_least "5.1.40" \
&& PBXT_NEWSTYLE=1

xtradb_patch_available \
&& XTRADB_P="percona-xtradb-${XTRADB_VER}" \
&& XTRADB_SRC_URI_COMMON="${PERCONA_VER}/source/${XTRADB_P}.tar.gz" \
&& XTRADB_SRC_B1="http://www.percona.com/" \
&& XTRADB_SRC_B2="${XTRADB_SRC_B1}/percona-builds/" \
&& XTRADB_SRC_URI1="${XTRADB_SRC_B2}/Percona-Server/Percona-Server-${XTRADB_SRC_URI_COMMON}" \
&& XTRADB_SRC_URI2="${XTRADB_SRC_B2}/xtradb/${XTRADB_SRC_URI_COMMON}" \
&& XTRADB_SRC_URI3="${XTRADB_SRC_B1}/${PN}/xtradb/${XTRADB_SRC_URI_COMMON}" \
&& SRC_URI="${SRC_URI} xtradb? ( ${XTRADB_SRC_URI1} ${XTRADB_SRC_URI2} ${XTRADB_SRC_URI3} )" \
&& IUSE="${IUSE} xtradb"

#
# HELPER FUNCTIONS:
#

# @FUNCTION: mysql_disable_test
# @DESCRIPTION:
# Helper function to disable specific tests.
mysql_disable_test() {
	local rawtestname testname testsuite reason mysql_disable_file
	rawtestname="${1}" ; shift
	reason="${@}"
	ewarn "test '${rawtestname}' disabled: '${reason}'"
	
	testsuite="${rawtestname/.*}"
	testname="${rawtestname/*.}"
	mysql_disable_file="${S}/mysql-test/t/disabled.def"
	#einfo "rawtestname=${rawtestname} testname=${testname} testsuite=${testsuite}"
	echo ${testname} : ${reason} >> "${mysql_disable_file}"

	# ${S}/mysql-tests/t/disabled.def
	#
	# ${S}/mysql-tests/suite/federated/disabled.def
	#
	# ${S}/mysql-tests/suite/jp/t/disabled.def
	# ${S}/mysql-tests/suite/ndb/t/disabled.def
	# ${S}/mysql-tests/suite/rpl/t/disabled.def
	# ${S}/mysql-tests/suite/parts/t/disabled.def
	# ${S}/mysql-tests/suite/rpl_ndb/t/disabled.def
	# ${S}/mysql-tests/suite/ndb_team/t/disabled.def
	# ${S}/mysql-tests/suite/binlog/t/disabled.def
	# ${S}/mysql-tests/suite/innodb/t/disabled.def
	if [ -n "${testsuite}" ]; then
		for mysql_disable_file in \
			${S}/mysql-test/suite/${testsuite}/disabled.def  \
			${S}/mysql-test/suite/${testsuite}/t/disabled.def  \
			FAILED ; do
			[ -f "${mysql_disable_file}" ] && break
		done
		if [ "${mysql_disabled_file}" != "FAILED" ]; then
			echo "${testname} : ${reason}" >> "${mysql_disable_file}"
		else
			ewarn "Could not find testsuite disabled.def location for ${rawtestname}"
		fi
	fi
}

# @FUNCTION: mysql_init_vars
# @DESCRIPTION:
# void mysql_init_vars()
# Initialize global variables
# 2005-11-19 <vivo@gentoo.org>
mysql_init_vars() {
	MY_SHAREDSTATEDIR=${MY_SHAREDSTATEDIR="/usr/share/mysql"}
	MY_SYSCONFDIR=${MY_SYSCONFDIR="/etc/mysql"}
	MY_LIBDIR=${MY_LIBDIR="/usr/$(get_libdir)/mysql"}
	MY_LOCALSTATEDIR=${MY_LOCALSTATEDIR="/var/lib/mysql"}
	MY_LOGDIR=${MY_LOGDIR="/var/log/mysql"}
	MY_INCLUDEDIR=${MY_INCLUDEDIR="/usr/include/mysql"}

	if [[ -z "${MY_DATADIR}" ]] ; then
		MY_DATADIR=""
		if [[ -f "${MY_SYSCONFDIR}/my.cnf" ]] ; then
			MY_DATADIR=`"my_print_defaults" mysqld 2>/dev/null \
				| sed -ne '/datadir/s|^--datadir=||p' \
				| tail -n1`
			if [[ -z "${MY_DATADIR}" ]] ; then
				MY_DATADIR=`grep ^datadir "${MY_SYSCONFDIR}/my.cnf" \
				| sed -e 's/.*=\s*//' \
				| tail -n1`
			fi
		fi
		if [[ -z "${MY_DATADIR}" ]] ; then
			MY_DATADIR="${MY_LOCALSTATEDIR}"
			einfo "Using default MY_DATADIR"
		fi
		elog "MySQL MY_DATADIR is ${MY_DATADIR}"

		if [[ -z "${PREVIOUS_DATADIR}" ]] ; then
			if [[ -e "${MY_DATADIR}" ]] ; then
				# If you get this and you're wondering about it, see bug #207636
				elog "MySQL datadir found in ${MY_DATADIR}"
				elog "A new one will not be created."
				PREVIOUS_DATADIR="yes"
			else
				PREVIOUS_DATADIR="no"
			fi
			export PREVIOUS_DATADIR
		fi
	else
		if [[ ${EBUILD_PHASE} == "config" ]]; then
			local new_MY_DATADIR
			new_MY_DATADIR=`"my_print_defaults" mysqld 2>/dev/null \
				| sed -ne '/datadir/s|^--datadir=||p' \
				| tail -n1`

			if [[ ( -n "${new_MY_DATADIR}" ) && ( "${new_MY_DATADIR}" != "${MY_DATADIR}" ) ]]; then
				ewarn "MySQL MY_DATADIR has changed"
				ewarn "from ${MY_DATADIR}"
				ewarn "to ${new_MY_DATADIR}"
				MY_DATADIR="${new_MY_DATADIR}"
			fi
		fi
	fi

	MY_SOURCEDIR=${SERVER_URI##*/}
	MY_SOURCEDIR=${MY_SOURCEDIR%.tar*}

	export MY_SHAREDSTATEDIR MY_SYSCONFDIR
	export MY_LIBDIR MY_LOCALSTATEDIR MY_LOGDIR
	export MY_INCLUDEDIR MY_DATADIR MY_SOURCEDIR
}

configure_minimal() {
	# These are things we exclude from a minimal build, please
	# note that the server actually does get built and installed,
	# but we then delete it before packaging.
	local minimal_exclude_list="server embedded-server extra-tools innodb bench berkeley-db row-based-replication readline"

	for i in ${minimal_exclude_list} ; do
		myconf="${myconf} --without-${i}"
	done
	myconf="${myconf} --with-extra-charsets=none"
	myconf="${myconf} --enable-local-infile"

	if use static ; then
		myconf="${myconf} --with-client-ldflags=-all-static"
		myconf="${myconf} --disable-shared --with-pic"
	else
		myconf="${myconf} --enable-shared --enable-static"
	fi

	if mysql_version_is_at_least "4.1" && ! use latin1 ; then
		myconf="${myconf} --with-charset=utf8"
		myconf="${myconf} --with-collation=utf8_general_ci"
	else
		myconf="${myconf} --with-charset=latin1"
		myconf="${myconf} --with-collation=latin1_swedish_ci"
	fi
}

configure_common() {
	myconf="${myconf} $(use_with big-tables)"
	myconf="${myconf} --enable-local-infile"
	myconf="${myconf} --with-extra-charsets=all"
	myconf="${myconf} --with-mysqld-user=mysql"
	myconf="${myconf} --with-server"
	myconf="${myconf} --with-unix-socket-path=/var/run/mysqld/mysqld.sock"
	myconf="${myconf} --without-libwrap"

	if use static ; then
		myconf="${myconf} --with-mysqld-ldflags=-all-static"
		myconf="${myconf} --with-client-ldflags=-all-static"
		myconf="${myconf} --disable-shared --with-pic"
	else
		myconf="${myconf} --enable-shared --enable-static"
	fi

	if use debug ; then
		myconf="${myconf} --with-debug=full"
	else
		myconf="${myconf} --without-debug"
		mysql_version_is_at_least "4.1.3" \
		&& use cluster \
		&& myconf="${myconf} --without-ndb-debug"
	fi

	if [ -n "${MYSQL_DEFAULT_CHARSET}" -a -n "${MYSQL_DEFAULT_COLLATION}" ]; then
		ewarn "You are using a custom charset of ${MYSQL_DEFAULT_CHARSET}"
		ewarn "and a collation of ${MYSQL_DEFAULT_COLLATION}."
		ewarn "You MUST file bugs without these variables set."
		myconf="${myconf} --with-charset=${MYSQL_DEFAULT_CHARSET}"
		myconf="${myconf} --with-collation=${MYSQL_DEFAULT_COLLATION}"
	elif mysql_version_is_at_least "4.1" && ! use latin1 ; then
		myconf="${myconf} --with-charset=utf8"
		myconf="${myconf} --with-collation=utf8_general_ci"
	else
		myconf="${myconf} --with-charset=latin1"
		myconf="${myconf} --with-collation=latin1_swedish_ci"
	fi

	if use embedded ; then
		myconf="${myconf} --with-embedded-privilege-control"
		myconf="${myconf} --with-embedded-server"

		# fix for amarok 2
		if mysql_version_is_at_least "5.1" ; then
			CFLAGS="${CFLAGS} -DPIC -fPIC"
			CXXFLAGS="${CXXFLAGS} -DPIC -fPIC"
		fi
	else
		myconf="${myconf} --without-embedded-privilege-control"
		myconf="${myconf} --without-embedded-server"
	fi

}

configure_40_41_50() {
	myconf="${myconf} $(use_with perl bench)"
	myconf="${myconf} --enable-assembler"
	myconf="${myconf} --with-extra-tools"
	myconf="${myconf} --with-innodb"
	myconf="${myconf} --without-readline"
	myconf="${myconf} $(use_with ssl openssl)"
	mysql_version_is_at_least "5.0" || myconf="${myconf} $(use_with raid)"

	# --with-vio is not needed anymore, it's on by default and
	# has been removed from configure
	#  Apply to 4.x and 5.0.[0-3]
	if use ssl ; then
		 mysql_version_is_at_least "5.0.4" || myconf="${myconf} --with-vio"
	fi

	if mysql_version_is_at_least "5.0.60" ; then
			if use berkdb ; then
				elog "Berkeley DB support was disabled due to build failures"
				elog "on multiple arches, go to a version earlier than 5.0.60"
				elog "if you want it again. Gentoo bug #224067."
			fi
			myconf="${myconf} --without-berkeley-db"
	elif use berkdb ; then
		# The following fix is due to a bug with bdb on SPARC's. See:
		# http://www.geocrawler.com/mail/msg.php3?msg_id=4754814&list=8
		# It comes down to non-64-bit safety problems.
		if use alpha || use amd64 || use hppa || use mips || use sparc ; then
			elog "Berkeley DB support was disabled due to compatibility issues on this arch"
			myconf="${myconf} --without-berkeley-db"
		else
			myconf="${myconf} --with-berkeley-db=./bdb"
		fi
	else
		myconf="${myconf} --without-berkeley-db"
	fi

	if mysql_version_is_at_least "4.1.3" ; then
		myconf="${myconf} --with-geometry"
		myconf="${myconf} $(use_with cluster ndbcluster)"
	fi

	if mysql_version_is_at_least "4.1.3" && use extraengine ; then
		# http://dev.mysql.com/doc/mysql/en/archive-storage-engine.html
		myconf="${myconf} --with-archive-storage-engine"

		# http://dev.mysql.com/doc/mysql/en/csv-storage-engine.html
		myconf="${myconf} --with-csv-storage-engine"

		# http://dev.mysql.com/doc/mysql/en/blackhole-storage-engine.html
		myconf="${myconf} --with-blackhole-storage-engine"

		# http://dev.mysql.com/doc/mysql/en/federated-storage-engine.html
		# http://dev.mysql.com/doc/mysql/en/federated-description.html
		# http://dev.mysql.com/doc/mysql/en/federated-limitations.html
		if mysql_version_is_at_least "5.0.3" ; then
			elog "Before using the Federated storage engine, please be sure to read"
			elog "http://dev.mysql.com/doc/mysql/en/federated-limitations.html"
			myconf="${myconf} --with-federated-storage-engine"
		fi
	fi

	if [ "${MYSQL_COMMUNITY_FEATURES}" == "1" ]; then
		myconf="${myconf} `use_enable community community-features`"
		if use community; then
			myconf="${myconf} `use_enable profiling`"
		else
			myconf="${myconf} --disable-profiling"
		fi
	fi

	mysql_version_is_at_least "5.0.18" \
	&& use max-idx-128 \
	&& myconf="${myconf} --with-max-indexes=128"
}

configure_51() {
	# TODO: !!!! readd --without-readline
	# the failure depend upon config/ac-macros/readline.m4 checking into
	# readline.h instead of history.h
	myconf="${myconf} $(use_with ssl ssl /usr)"
	myconf="${myconf} --enable-assembler"
	myconf="${myconf} --with-geometry"
	myconf="${myconf} --with-readline"
	myconf="${myconf} --with-zlib-dir=/usr/"
	myconf="${myconf} --without-pstack"
	myconf="${myconf} --with-plugindir=/usr/$(get_libdir)/mysql/plugin"

	use max-idx-128 && myconf="${myconf} --with-max-indexes=128"
	if [ "${MYSQL_COMMUNITY_FEATURES}" == "1" ]; then
		myconf="${myconf} $(use_enable community community-features)"
		if use community; then
			myconf="${myconf} $(use_enable profiling)"
		else
			myconf="${myconf} --disable-profiling"
		fi
	fi

	# Scan for all available plugins
	local plugins_avail="$(
	LANG=C \
	find "${S}" \
		\( \
		-name 'plug.in' \
		-o -iname 'configure.in' \
		-o -iname 'configure.ac' \
		\) \
		-print0 \
	| xargs -0 sed -r -n \
		-e '/^MYSQL_STORAGE_ENGINE/{
			s~MYSQL_STORAGE_ENGINE\([[:space:]]*\[?([-_a-z0-9]+)\]?.*,~\1 ~g ;
			s~^([^ ]+).*~\1~gp; 
		}' \
	| tr -s '\n' ' '
	)"

	# 5.1 introduces a new way to manage storage engines (plugins)
	# like configuration=none
	# This base set are required, and will always be statically built.
	local plugins_sta="csv myisam myisammrg heap"
	local plugins_dyn=""
	local plugins_dis="example ibmdb2i"

	# These aren't actually required by the base set, but are really useful:
	plugins_sta="${plugins_sta} archive blackhole"

	# default in 5.5.4
	if mysql_version_is_at_least "5.5.4" ; then
		plugins_sta="${plugins_sta} partition"
	fi
	# Now the extras
	if use extraengine ; then
		# like configuration=max-no-ndb, archive and example removed in 5.1.11
		# not added yet: ibmdb2i
		# Not supporting as examples: example,daemon_example,ftexample 
		plugins_sta="${plugins_sta} partition"
		plugins_dyn="${plugins_sta} federated"

		if [[ "${PN}" != "mariadb" ]] ; then
			elog "Before using the Federated storage engine, please be sure to read"
			elog "http://dev.mysql.com/doc/refman/5.1/en/federated-limitations.html"
		else
			elog "MariaDB includes the FederatedX engine. Be sure to read"
			elog "http://askmonty.org/wiki/index.php/Manual:FederatedX_storage_engine"
		fi
	else
		plugins_dis="${plugins_dis} partition federated"
	fi

	# Upstream specifically requests that InnoDB always be built:
	# - innobase, innodb_plugin
	# Build falcon if available for 6.x series.
	for i in innobase falcon ; do
		[ -e "${S}"/storage/${i} ] && plugins_sta="${plugins_sta} ${i}"
	done
	for i in innodb_plugin ; do
		[ -e "${S}"/storage/${i} ] && plugins_dyn="${plugins_dyn} ${i}"
	done

	# like configuration=max-no-ndb
	if use cluster ; then
		plugins_sta="${plugins_sta} ndbcluster partition"
		plugins_dis="${plugins_dis//partition}"
		myconf="${myconf} --with-ndb-binlog"
	else
		plugins_dis="${plugins_dis} ndbcluster"
	fi

	if [[ "${PN}" == "mariadb" ]] ; then
		# In MariaDB, InnoDB is packaged in the xtradb directory, so it's not
		# caught above.
		plugins_sta="${plugins_sta} maria innobase"
		myconf="${myconf} $(use_with libevent)"
		# This is not optional, without it several upstream testcases fail.
		# Also strongly recommended by upstream.
		myconf="${myconf} --with-maria-tmp-tables"
	fi
	
	if pbxt_available && [[ "${PBXT_NEWSTYLE}" == "1" ]]; then
		use pbxt \
		&& plugins_dyn="${plugins_dyn} pbxt" \
		|| plugins_dis="${plugins_dis} pbxt"
	fi

	use static && \
	plugins_sta="${plugins_sta} ${plugins_dyn}" && \
	plugins_dyn=""
	
	einfo "Available plugins: ${plugins_avail}"
	einfo "Dynamic plugins: ${plugins_dyn}"
	einfo "Static plugins: ${plugins_sta}"
	einfo "Disabled plugins: ${plugins_dis}"

	# These are the static plugins
	myconf="${myconf} --with-plugins=${plugins_sta// /,}"
	# And the disabled ones
	for i in ${plugins_dis} ; do
		myconf="${myconf} --without-plugin-${i}"
	done
}

pbxt_src_configure() {
	mysql_init_vars

	pushd "${WORKDIR}/pbxt-${PBXT_VERSION}" &>/dev/null

	einfo "Reconfiguring dir '${PWD}'"
	AT_GNUCONF_UPDATE="yes" eautoreconf

	local myconf=""
	myconf="${myconf} --with-mysql=${S} --libdir=/usr/$(get_libdir)"
	use debug && myconf="${myconf} --with-debug=full"
	econf ${myconf} || die "Problem configuring PBXT storage engine"
}

pbxt_src_compile() {

	# Be backwards compatible for now
	if [[ $EAPI != 2 ]]; then
		pbxt_src_configure
	fi
	# TODO: is it safe/needed to use emake here ?
	make || die "Problem making PBXT storage engine (${myconf})"

	popd
	# TODO: modify test suite for PBXT
}

pbxt_src_install() {
	pushd "${WORKDIR}/pbxt-${PBXT_VERSION}" &>/dev/null
		emake install DESTDIR="${D}" || die "Failed to install PBXT"
	popd
}

#
# EBUILD FUNCTIONS
#
# @FUNCTION: mysql_pkg_setup
# @DESCRIPTION:
# Perform some basic tests and tasks during pkg_setup phase:
#   die if FEATURES="test", USE="-minimal" and not using FEATURES="userpriv"
#   check for conflicting use flags
#   create new user and group for mysql
#   warn about deprecated features
mysql_pkg_setup() {
	if hasq test ${FEATURES} ; then
		if ! use minimal ; then
			if [[ $UID -eq 0 ]]; then
				eerror "Testing with FEATURES=-userpriv is no longer supported by upstream. Tests MUST be run as non-root."
			fi
		fi
	fi

	# Check for USE flag problems in pkg_setup
	if use static && use ssl ; then
		M="MySQL does not support being built statically with SSL support enabled!"
		eerror "${M}"
		die "${M}"
	fi

	if ! mysql_version_is_at_least "5.0" \
	&& use raid \
	&& use static ; then
		eerror "USE flags 'raid' and 'static' conflict, you cannot build MySQL statically"
		eerror "with RAID support enabled."
		die "USE flags 'raid' and 'static' conflict!"
	fi

	if mysql_version_is_at_least "4.1.3" \
	&& ( use cluster || use extraengine || use embedded ) \
	&& use minimal ; then
		M="USE flags 'cluster', 'extraengine', 'embedded' conflict with 'minimal' USE flag!"
		eerror "${M}"
		die "${M}"
	fi
	
	if mysql_version_is_at_least "5.1" \
	&& xtradb_patch_available \
	&& use xtradb \
	&& use embedded ; then
		M="USE flags 'xtradb' and 'embedded' conflict and cause build failures"
		eerror "${M}"
		die "${M}"
	fi

	# Bug #290570, 284946, 307251
	# Upstream changes made us need a fairly new GCC4.
	# But only for 5.0.8[3-6]!
	if mysql_version_is_at_least "5.0.83"  && ! mysql_version_is_at_least 5.0.87 ; then
		GCC_VER=$(gcc-version)
		case ${GCC_VER} in
			2*|3*|4.0|4.1|4.2) 
			eerror "Some releases of MySQL required a very new GCC, and then"
			eerror "later release relaxed that requirement again. Either pick a"
			eerror "MySQL >=5.0.87, or use a newer GCC."
			die "Active GCC too old!" ;;
		esac
	fi

	# This should come after all of the die statements
	enewgroup mysql 60 || die "problem adding 'mysql' group"
	enewuser mysql 60 -1 /dev/null mysql || die "problem adding 'mysql' user"

	mysql_check_version_range "4.0 to 5.0.99.99" \
	&& use berkdb \
	&& elog "Berkeley DB support is deprecated and will be removed in future versions!"

	if [ "${PN}" != "mysql-cluster" ] && use cluster; then
		ewarn "Upstream has noted that the NDB cluster support in the 5.0 and"
		ewarn "5.1 series should NOT be put into production. In the near"
		ewarn "future, it will be disabled from building."
		ewarn ""
		ewarn "If you need NDB support, you should instead move to the new"
		ewarn "mysql-cluster package that represents that upstream NDB"
		ewarn "development."
	fi
}

# @FUNCTION: mysql_src_unpack
# @DESCRIPTION:
# Unpack the source code and call mysql_src_prepare for EAPI < 2.
mysql_src_unpack() {
	# Initialize the proper variables first
	mysql_init_vars

	unpack ${A}
	# Grab the patches
	[[ "${MY_EXTRAS_VER}" == "live" ]] && S="${WORKDIR}/mysql-extras" git_src_unpack

	mv -f "${WORKDIR}/${MY_SOURCEDIR}" "${S}"

	# Be backwards compatible for now
	case ${EAPI:-0} in
        	2) : ;;
        	0 | 1) mysql_src_prepare ;;
	esac
}

# @FUNCTION: mysql_src_prepare
# @DESCRIPTION:
# Apply patches to the source code and remove unneeded bundled libs.
mysql_src_prepare() {
	cd "${S}"

	# Apply the patches for this MySQL version
	EPATCH_SUFFIX="patch"
	mkdir -p "${EPATCH_SOURCE}" || die "Unable to create epatch directory"
	# Clean out old items
	rm -f "${EPATCH_SOURCE}"/*
	# Now link in right patches
	mysql_mv_patches
	# And apply
	epatch

	# last -fPIC fixup, per bug #305873
	i="${S}"/storage/innodb_plugin/plug.in	
	[ -f "${i}" ] && sed -i -e '/CFLAGS/s,-prefer-non-pic,,g' "${i}"

	# Additional checks, remove bundled zlib
	rm -f "${S}/zlib/"*.[ch]
	sed -i -e "s/zlib\/Makefile dnl/dnl zlib\/Makefile/" "${S}/configure.in"
	rm -f "scripts/mysqlbug"

	# Make charsets install in the right place
	find . -name 'Makefile.am' \
		-exec sed --in-place -e 's!$(pkgdatadir)!'${MY_SHAREDSTATEDIR}'!g' {} \;

	if mysql_version_is_at_least "4.1" ; then
		# Remove what needs to be recreated, so we're sure it's actually done
		einfo "Cleaning up old buildscript files"
		find . -name Makefile \
			-o -name Makefile.in \
			-o -name configure \
			-exec rm -f {} \;
		rm -f "ltmain.sh"
		rm -f "scripts/mysqlbug"
	fi

	local rebuilddirlist d

	if xtradb_patch_available && use xtradb ; then
		einfo "Adding storage engine: Percona XtraDB (replacing InnoDB)"
		pushd "${S}"/storage >/dev/null
		i="innobase"
		o="${WORKDIR}/storage-${i}.mysql-upstream"
		# Have we been here already?
		[ -d "${o}" ] && rm -f "${i}"
		# Or maybe we haven't
		[ -d "${i}" -a ! -d "${o}" ] && mv "${i}" "${o}"
		cp -ral "${WORKDIR}/${XTRADB_P}" "${i}"
		popd >/dev/null
	fi
	
	if pbxt_available && [[ "${PBXT_NEWSTYLE}" == "1" ]] && use pbxt ; then
		einfo "Adding storage engine: PBXT"
		pushd "${S}"/storage >/dev/null
		i='pbxt'
		[ -d "${i}" ] && rm -rf "${i}"
		cp -ral "${WORKDIR}/${PBXT_P}" "${i}"
		popd >/dev/null
	fi

	if mysql_version_is_at_least "5.1.12" ; then
		rebuilddirlist="."
		# This does not seem to be needed presently. robbat2 2010/02/23
		#einfo "Updating innobase cmake"
		## TODO: check this with a cmake expert
		#cmake \
		#	-DCMAKE_C_COMPILER=$(type -P $(tc-getCC)) \
		#	-DCMAKE_CXX_COMPILER=$(type -P $(tc-getCXX)) \
		#	"storage/innobase"
	else
		rebuilddirlist=". innobase"
	fi

	for d in ${rebuilddirlist} ; do
		einfo "Reconfiguring dir '${d}'"
		pushd "${d}" &>/dev/null
		AT_GNUCONF_UPDATE="yes" eautoreconf
		popd &>/dev/null
	done

	if mysql_check_version_range "4.1 to 5.0.99.99" \
	&& use berkdb ; then
		einfo "Fixing up berkdb buildsystem"
		[[ -w "bdb/dist/ltmain.sh" ]] && cp -f "ltmain.sh" "bdb/dist/ltmain.sh"
		cp -f "/usr/share/aclocal/libtool.m4" "bdb/dist/aclocal/libtool.ac" \
		|| die "Could not copy libtool.m4 to bdb/dist/"
		#These files exist only with libtool-2*, and need to be included.
		if [ -f '/usr/share/aclocal/ltsugar.m4' ]; then
			cat "/usr/share/aclocal/ltsugar.m4" >>  "bdb/dist/aclocal/libtool.ac"
			cat "/usr/share/aclocal/ltversion.m4" >>  "bdb/dist/aclocal/libtool.ac"
			cat "/usr/share/aclocal/lt~obsolete.m4" >>  "bdb/dist/aclocal/libtool.ac"
			cat "/usr/share/aclocal/ltoptions.m4" >>  "bdb/dist/aclocal/libtool.ac"
		fi
		pushd "bdb/dist" &>/dev/null
		sh s_all \
		|| die "Failed bdb reconfigure"
		popd &>/dev/null
	fi
}

# @FUNCTION: mysql_src_configure
# @DESCRIPTION:
# Configure mysql to build the code for Gentoo respecting the use flags.
mysql_src_configure() {
	# Make sure the vars are correctly initialized
	mysql_init_vars

	# $myconf is modified by the configure_* functions
	local myconf=""

	if use minimal ; then
		configure_minimal
	else
		configure_common
		if mysql_version_is_at_least "5.1.10" ; then
			configure_51
		else
			configure_40_41_50
		fi
	fi

	# Bug #114895, bug #110149
	filter-flags "-O" "-O[01]"

	# glib-2.3.2_pre fix, bug #16496
	append-flags "-DHAVE_ERRNO_AS_DEFINE=1"

	# As discovered by bug #246652, doing a double-level of SSP causes NDB to
	# fail badly during cluster startup.
	if [[ $(gcc-major-version) -lt 4 ]]; then
		filter-flags "-fstack-protector-all"
	fi

	CXXFLAGS="${CXXFLAGS} -fno-exceptions -fno-strict-aliasing"
	CXXFLAGS="${CXXFLAGS} -felide-constructors -fno-rtti"
	mysql_version_is_at_least "5.0" \
	&& CXXFLAGS="${CXXFLAGS} -fno-implicit-templates"
	export CXXFLAGS

	# bug #283926, with GCC4.4, this is required to get correct behavior.
	append-flags -fno-strict-aliasing

	econf \
		--libexecdir="/usr/sbin" \
		--sysconfdir="${MY_SYSCONFDIR}" \
		--localstatedir="${MY_LOCALSTATEDIR}" \
		--sharedstatedir="${MY_SHAREDSTATEDIR}" \
		--libdir="${MY_LIBDIR}" \
		--includedir="${MY_INCLUDEDIR}" \
		--with-low-memory \
		--with-client-ldflags=-lstdc++ \
		--enable-thread-safe-client \
		--with-comment="Gentoo Linux ${PF}" \
		--without-docs \
		${myconf} || die "econf failed"

	# TODO: Move this before autoreconf !!!
	find . -type f -name Makefile -print0 \
	| xargs -0 -n100 sed -i \
	-e 's|^pkglibdir *= *$(libdir)/mysql|pkglibdir = $(libdir)|;s|^pkgincludedir *= *$(includedir)/mysql|pkgincludedir = $(includedir)|'

	if [[ $EAPI == 2 ]] && [[ "${PBXT_NEWSTYLE}" != "1" ]]; then
		pbxt_patch_available && use pbxt && pbxt_src_configure
	fi
}

# @FUNCTION: mysql_src_compile
# @DESCRIPTION:
# Compile the mysql code.
mysql_src_compile() {
	# Be backwards compatible for now
	case ${EAPI:-0} in
		2) : ;;
		0 | 1) mysql_src_configure ;;
	esac

	emake || die "emake failed"

	if [[ "${PBXT_NEWSTYLE}" != "1" ]]; then
		pbxt_patch_available && use pbxt && pbxt_src_compile
	fi
}

# @FUNCTION: mysql_src_install
# @DESCRIPTION:
# Install mysql.
mysql_src_install() {
	# Make sure the vars are correctly initialized
	mysql_init_vars

	emake install \
		DESTDIR="${D}" \
		benchdir_root="${MY_SHAREDSTATEDIR}" \
		testroot="${MY_SHAREDSTATEDIR}" \
		|| die "emake install failed"

	if [[ "${PBXT_NEWSTYLE}" != "1" ]]; then
		pbxt_patch_available && use pbxt && pbxt_src_install
	fi

	# Convenience links
	einfo "Making Convenience links for mysqlcheck multi-call binary"
	dosym "/usr/bin/mysqlcheck" "/usr/bin/mysqlanalyze"
	dosym "/usr/bin/mysqlcheck" "/usr/bin/mysqlrepair"
	dosym "/usr/bin/mysqlcheck" "/usr/bin/mysqloptimize"

	# Various junk (my-*.cnf moved elsewhere)
	einfo "Removing duplicate /usr/share/mysql files"
	rm -Rf "${D}/usr/share/info"
	for removeme in  "mysql-log-rotate" mysql.server* \
		binary-configure* my-*.cnf mi_test_all*
	do
		rm -f "${D}"/${MY_SHAREDSTATEDIR}/${removeme}
	done

	# Clean up stuff for a minimal build
	if use minimal ; then
		einfo "Remove all extra content for minimal build"
		rm -Rf "${D}${MY_SHAREDSTATEDIR}"/{mysql-test,sql-bench}
		rm -f "${D}"/usr/bin/{mysql{_install_db,manager*,_secure_installation,_fix_privilege_tables,hotcopy,_convert_table_format,d_multi,_fix_extensions,_zap,_explain_log,_tableinfo,d_safe,_install,_waitpid,binlog,test},myisam*,isam*,pack_isam}
		rm -f "${D}/usr/sbin/mysqld"
		rm -f "${D}${MY_LIBDIR}"/lib{heap,merge,nisam,my{sys,strings,sqld,isammrg,isam},vio,dbug}.a
	fi

	# Unless they explicitly specific USE=test, then do not install the
	# testsuite. It DOES have a use to be installed, esp. when you want to do a
	# validation of your database configuration after tuning it.
	if use !test ; then
		rm -rf "${D}"/${MY_SHAREDSTATEDIR}/mysql-test
	fi

	# Configuration stuff
	if mysql_version_is_at_least "5.1" ; then
		mysql_mycnf_version="5.1"
	elif mysql_version_is_at_least "4.1" ; then
		mysql_mycnf_version="4.1"
	else
		mysql_mycnf_version="4.0"
	fi
	einfo "Building default my.cnf"
	insinto "${MY_SYSCONFDIR}"
	doins scripts/mysqlaccess.conf
	sed -e "s!@DATADIR@!${MY_DATADIR}!g" \
		"${FILESDIR}/my.cnf-${mysql_mycnf_version}" \
		> "${TMPDIR}/my.cnf.ok"
	if mysql_version_is_at_least "4.1" && use latin1 ; then
		sed -i \
			-e "/character-set/s|utf8|latin1|g" \
			"${TMPDIR}/my.cnf.ok"
	fi
	newins "${TMPDIR}/my.cnf.ok" my.cnf

	# Minimal builds don't have the MySQL server
	if ! use minimal ; then
		einfo "Creating initial directories"
		# Empty directories ...
		diropts "-m0750"
		if [[ "${PREVIOUS_DATADIR}" != "yes" ]] ; then
			dodir "${MY_DATADIR}"
			keepdir "${MY_DATADIR}"
			chown -R mysql:mysql "${D}/${MY_DATADIR}"
		fi

		diropts "-m0755"
		for folder in "${MY_LOGDIR}" "/var/run/mysqld" ; do
			dodir "${folder}"
			keepdir "${folder}"
			chown -R mysql:mysql "${D}/${folder}"
		done
	fi

	# Docs
	einfo "Installing docs"
	dodoc README ChangeLog EXCEPTIONS-CLIENT INSTALL-SOURCE
	doinfo "${S}"/Docs/mysql.info

	# Minimal builds don't have the MySQL server
	if ! use minimal ; then
		einfo "Including support files and sample configurations"
		docinto "support-files"
		for script in \
			"${S}"/support-files/my-*.cnf \
			"${S}"/support-files/magic \
			"${S}"/support-files/ndb-config-2-node.ini
		do
			[[ -f "$script" ]] && dodoc "${script}"
		done

		docinto "scripts"
		for script in "${S}"/scripts/mysql* ; do
			[[ -f "$script" ]] && [[ "${script%.sh}" == "${script}" ]] && dodoc "${script}"
		done

	fi

	mysql_lib_symlinks "${D}"
}

# @FUNCTION: mysql_pkg_preinst
# @DESCRIPTION:
# Create the user and groups for mysql - die if that fails.
mysql_pkg_preinst() {
	enewgroup mysql 60 || die "problem adding 'mysql' group"
	enewuser mysql 60 -1 /dev/null mysql || die "problem adding 'mysql' user"
}

# @FUNCTION: mysql_pkg_postinst
# @DESCRIPTION:
# Run post-installation tasks:
#   create the dir for logfiles if non-existant
#   touch the logfiles and secure them
#   install scripts
#   issue required steps for optional features
#   issue deprecation warnings
mysql_pkg_postinst() {
	# Make sure the vars are correctly initialized
	mysql_init_vars

	# Check FEATURES="collision-protect" before removing this
	[[ -d "${ROOT}/var/log/mysql" ]] || install -d -m0750 -o mysql -g mysql "${ROOT}${MY_LOGDIR}"

	# Secure the logfiles
	touch "${ROOT}${MY_LOGDIR}"/mysql.{log,err}
	chown mysql:mysql "${ROOT}${MY_LOGDIR}"/mysql*
	chmod 0660 "${ROOT}${MY_LOGDIR}"/mysql*

	# Minimal builds don't have the MySQL server
	if ! use minimal ; then
		docinto "support-files"
		for script in \
			support-files/my-*.cnf \
			support-files/magic \
			support-files/ndb-config-2-node.ini
		do
			[[ -f "${script}" ]] \
			&& dodoc "${script}"
		done

		docinto "scripts"
		for script in scripts/mysql* ; do
			[[ -f "${script}" ]] \
			&& [[ "${script%.sh}" == "${script}" ]] \
			&& dodoc "${script}"
		done

		einfo
		elog "You might want to run:"
		elog "\"emerge --config =${CATEGORY}/${PF}\""
		elog "if this is a new install."
		einfo
	fi

	if pbxt_available && use pbxt ; then
		# TODO: explain it better
		elog "    mysql> INSTALL PLUGIN pbxt SONAME 'libpbxt.so';"
		elog "    mysql> CREATE TABLE t1 (c1 int, c2 text) ENGINE=pbxt;"
		elog "if, after that, you cannot start the MySQL server,"
		elog "remove the ${MY_DATADIR}/mysql/plugin.* files, then"
		elog "use the MySQL upgrade script to restore the table"
		elog "or execute the following SQL command:"
		elog "    CREATE TABLE IF NOT EXISTS plugin ("
		elog "      name char(64) binary DEFAULT '' NOT NULL,"
		elog "      dl char(128) DEFAULT '' NOT NULL,"
		elog "      PRIMARY KEY (name)"
		elog "    ) CHARACTER SET utf8 COLLATE utf8_bin;"
	fi

	mysql_check_version_range "4.0 to 5.0.99.99" \
	&& use berkdb \
	&& elog "Berkeley DB support is deprecated and will be removed in future versions!"
}

# @FUNCTION: mysql_pkg_config
# @DESCRIPTION:
# Configure mysql environment.
mysql_pkg_config() {
	local old_MY_DATADIR="${MY_DATADIR}"

	# Make sure the vars are correctly initialized
	mysql_init_vars

	[[ -z "${MY_DATADIR}" ]] && die "Sorry, unable to find MY_DATADIR"

	if built_with_use ${CATEGORY}/${PN} minimal ; then
		die "Minimal builds do NOT include the MySQL server"
	fi

	if [[ ( -n "${MY_DATADIR}" ) && ( "${MY_DATADIR}" != "${old_MY_DATADIR}" ) ]]; then
		local MY_DATADIR_s="$(strip_duplicate_slashes ${ROOT}/${MY_DATADIR})"
		local old_MY_DATADIR_s="$(strip_duplicate_slashes ${ROOT}/${old_MY_DATADIR})"

		if [[ -d "${old_MY_DATADIR_s}" ]]; then
			if [[ -d "${MY_DATADIR_s}" ]]; then
				ewarn "Both ${old_MY_DATADIR_s} and ${MY_DATADIR_s} exist"
				ewarn "Attempting to use ${MY_DATADIR_s} and preserving ${old_MY_DATADIR_s}"
			else
				elog "Moving MY_DATADIR from ${old_MY_DATADIR_s} to ${MY_DATADIR_s}"
				mv --strip-trailing-slashes -T "${old_MY_DATADIR_s}" "${MY_DATADIR_s}" \
				|| die "Moving MY_DATADIR failed"
			fi
		else
			ewarn "Previous MY_DATADIR (${old_MY_DATADIR_s}) does not exist"
			if [[ -d "${MY_DATADIR_s}" ]]; then
				ewarn "Attempting to use ${MY_DATADIR_s}"
			else
				eerror "New MY_DATADIR (${MY_DATADIR_s}) does not exist"
				die "Configuration Failed!  Please reinstall ${CATEGORY}/${PN}"
			fi
		fi
	fi

	local pwd1="a"
	local pwd2="b"
	local MYSQL_ROOT_PASSWORD=''
	local maxtry=15

	if [ -z "${MYSQL_ROOT_PASSWORD}" -a -f "${ROOT}/root/.my.cnf" ]; then
		MYSQL_ROOT_PASSWORD="$(sed -n -e '/^password=/s,^password=,,gp' "${ROOT}/root/.my.cnf")"
	fi

	if [[ -d "${ROOT}/${MY_DATADIR}/mysql" ]] ; then
		ewarn "You have already a MySQL database in place."
		ewarn "(${ROOT}/${MY_DATADIR}/*)"
		ewarn "Please rename or delete it if you wish to replace it."
		die "MySQL database already exists!"
	fi

	# Bug #213475 - MySQL _will_ object strenously if your machine is named
	# localhost. Also causes weird failures.
	[[ "${HOSTNAME}" == "localhost" ]] && die "Your machine must NOT be named localhost"

	if [ -z "${MYSQL_ROOT_PASSWORD}" ]; then

		einfo "Please provide a password for the mysql 'root' user now,"
		einfo "or in the MYSQL_ROOT_PASSWORD env var."
		ewarn "Avoid [\"'\\_%] characters in the password"
		read -rsp "    >" pwd1 ; echo

		einfo "Retype the password"
		read -rsp "    >" pwd2 ; echo

		if [[ "x$pwd1" != "x$pwd2" ]] ; then
			die "Passwords are not the same"
		fi
		MYSQL_ROOT_PASSWORD="${pwd1}"
		unset pwd1 pwd2
	fi

	local options=""
	local sqltmp="$(emktemp)"

	local help_tables="${ROOT}${MY_SHAREDSTATEDIR}/fill_help_tables.sql"
	[[ -r "${help_tables}" ]] \
	&& cp "${help_tables}" "${TMPDIR}/fill_help_tables.sql" \
	|| touch "${TMPDIR}/fill_help_tables.sql"
	help_tables="${TMPDIR}/fill_help_tables.sql"

	pushd "${TMPDIR}" &>/dev/null
	"${ROOT}/usr/bin/mysql_install_db" >"${TMPDIR}"/mysql_install_db.log 2>&1
	if [ $? -ne 0 ]; then
		grep -B5 -A999 -i "ERROR" "${TMPDIR}"/mysql_install_db.log 1>&2
		die "Failed to run mysql_install_db. Please review /var/log/mysql/mysqld.err AND ${TMPDIR}/mysql_install_db.log"
	fi
	popd &>/dev/null
	[[ -f "${ROOT}/${MY_DATADIR}/mysql/user.frm" ]] \
	|| die "MySQL databases not installed"
	chown -R mysql:mysql "${ROOT}/${MY_DATADIR}" 2>/dev/null
	chmod 0750 "${ROOT}/${MY_DATADIR}" 2>/dev/null

	# Figure out which options we need to disable to do the setup
	helpfile="${TMPDIR}/mysqld-help"
	${ROOT}/usr/sbin/mysqld --verbose --help >"${helpfile}" 2>/dev/null
	for opt in grant-tables host-cache name-resolve networking slave-start bdb \
		federated innodb ssl log-bin relay-log slow-query-log external-locking \
		; do
		optexp="--(skip-)?${opt}" optfull="--skip-${opt}"
		egrep -sq -- "${optexp}" "${helpfile}" && options="${options} ${optfull}"
	done
	# But some options changed names
	egrep -sq external-locking "${helpfile}" && \
	options="${options/skip-locking/skip-external-locking}"

	if mysql_version_is_at_least "4.1.3" ; then
		# Filling timezones, see
		# http://dev.mysql.com/doc/mysql/en/time-zone-support.html
		"${ROOT}/usr/bin/mysql_tzinfo_to_sql" "${ROOT}/usr/share/zoneinfo" > "${sqltmp}" 2>/dev/null

		if [[ -r "${help_tables}" ]] ; then
			cat "${help_tables}" >> "${sqltmp}"
		fi
	fi
	
	einfo "Creating the mysql database and setting proper"
	einfo "permissions on it ..."

	local socket="${ROOT}/var/run/mysqld/mysqld${RANDOM}.sock"
	local pidfile="${ROOT}/var/run/mysqld/mysqld${RANDOM}.pid"
	local mysqld="${ROOT}/usr/sbin/mysqld \
		${options} \
		--user=mysql \
		--basedir=${ROOT}/usr \
		--datadir=${ROOT}/${MY_DATADIR} \
		--max_allowed_packet=8M \
		--net_buffer_length=16K \
		--default-storage-engine=MyISAM \
		--socket=${socket} \
		--pid-file=${pidfile}"
	#einfo "About to start mysqld: ${mysqld}"
	ebegin "Starting mysqld"
	${mysqld} &
	rc=$?
	while ! [[ -S "${socket}" || "${maxtry}" -lt 1 ]] ; do
		maxtry=$((${maxtry}-1))
		echo -n "."
		sleep 1
	done
	eend $rc

	if ! [[ -S "${socket}" ]]; then
		die "Completely failed to start up mysqld with: ${mysqld}"
	fi

	ebegin "Setting root password"
	# Do this from memory, as we don't want clear text passwords in temp files
	local sql="UPDATE mysql.user SET Password = PASSWORD('${MYSQL_ROOT_PASSWORD}') WHERE USER='root'"
	"${ROOT}/usr/bin/mysql" \
		--socket=${socket} \
		-hlocalhost \
		-e "${sql}"
	eend $?

	ebegin "Loading \"zoneinfo\", this step may require a few seconds ..."
	"${ROOT}/usr/bin/mysql" \
		--socket=${socket} \
		-hlocalhost \
		-uroot \
		-p"${MYSQL_ROOT_PASSWORD}" \
		mysql < "${sqltmp}"
	rc=$?
	eend $?
	[ $rc -ne 0 ] && ewarn "Failed to load zoneinfo!"

	# Stop the server and cleanup
	einfo "Stopping the server ..."
	kill $(< "${pidfile}" )
	rm -f "${sqltmp}"
	wait %1
	einfo "Done"
}

# @FUNCTION: mysql_pkg_postrm
# @DESCRIPTION:
# Remove mysql symlinks.
mysql_pkg_postrm() {
	: # mysql_lib_symlinks "${D}"
}
