# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/mail-mta/postfix/postfix-2.8.12.ebuild,v 1.1 2012/08/02 14:02:39 eras Exp $

EAPI=4

inherit eutils multilib ssl-cert toolchain-funcs flag-o-matic pam user

MY_PV="${PV/_rc/-RC}"
MY_SRC="${PN}-${MY_PV}"
MY_URI="ftp://ftp.porcupine.org/mirrors/postfix-release/official"
VDA_PV="2.8.9"
VDA_P="${PN}-vda-v10-${VDA_PV}"
RC_VER="2.7"

DESCRIPTION="A fast and secure drop-in replacement for sendmail."
HOMEPAGE="http://www.postfix.org/"
SRC_URI="${MY_URI}/${MY_SRC}.tar.gz
	vda? ( http://vda.sourceforge.net/VDA/${VDA_P}.patch ) "

LICENSE="IBM"
SLOT="0"
KEYWORDS="*"
IUSE="cdb doc dovecot-sasl hardened ipv6 ldap ldap-bind mbox mysql nis pam postgres sasl selinux sqlite ssl vda"

DEPEND=">=sys-libs/db-3.2
	>=dev-libs/libpcre-3.4
	net-mail/mailbase
	dev-lang/perl
	cdb? ( || ( >=dev-db/tinycdb-0.76 >=dev-db/cdb-0.75-r1 ) )
	ldap? ( net-nds/openldap )
	ldap-bind? ( net-nds/openldap[sasl] )
	mysql? ( virtual/mysql )
	pam? ( virtual/pam )
	postgres? ( dev-db/postgresql-base )
	sasl? (  >=dev-libs/cyrus-sasl-2 )
	sqlite? ( dev-db/sqlite:3 )
	ssl? ( >=dev-libs/openssl-0.9.6g )"

RDEPEND="${DEPEND}
	dovecot-sasl? ( net-mail/dovecot )
	selinux? ( sec-policy/selinux-postfix )
	!mail-mta/courier
	!mail-mta/esmtp
	!mail-mta/exim
	!mail-mta/mini-qmail
	!mail-mta/msmtp[mta]
	!mail-mta/nbsmtp
	!mail-mta/netqmail
	!mail-mta/nullmailer
	!mail-mta/qmail-ldap
	!mail-mta/sendmail
	!<mail-mta/ssmtp-2.64-r2
	!>=mail-mta/ssmtp-2.64-r2[mta]
	!net-mail/fastforward"

REQUIRED_USE="ldap-bind? ( ldap sasl )"

S="${WORKDIR}/${MY_SRC}"

group_user_check() {
	einfo "Checking for postfix group ..."
	enewgroup postfix 207
	einfo "Checking for postdrop group ..."
	enewgroup postdrop 208
	einfo "Checking for postfix user ..."
	enewuser postfix 207 -1 /var/spool/postfix postfix,mail
}

pkg_setup() {
	# Add postfix, postdrop user/group (bug #77565)
	group_user_check || die "Failed to check/add needed user/group"
}

src_prepare() {
	if use vda ; then
		epatch "${DISTDIR}"/${VDA_P}.patch
	fi

	sed -i -e "/^#define ALIAS_DB_MAP/s|:/etc/aliases|:/etc/mail/aliases|" \
		src/util/sys_defs.h || die "sed failed"

	# change default paths to better comply with portage standard paths
	sed -i -e "s:/usr/local/:/usr/:g" conf/master.cf || die "sed failed"
	# changeto unix socke and use chrooted deamon
	epatch "$FILESDIR"/$PN-funtoo.patch
}

src_configure() {
	# Make sure LDFLAGS get passed down to the executables.
	local mycc="-DHAS_PCRE" mylibs="${LDFLAGS} -lpcre -lcrypt -lpthread"

	use pam && mylibs="${mylibs} -lpam"

	if use ldap ; then
		mycc="${mycc} -DHAS_LDAP"
		mylibs="${mylibs} -lldap -llber"
	fi

	if use mysql ; then
		mycc="${mycc} -DHAS_MYSQL $(mysql_config --include)"
		mylibs="${mylibs} $(mysql_config --libs)"
	fi

	if use postgres ; then
		mycc="${mycc} -DHAS_PGSQL -I$(pg_config --includedir)"
		mylibs="${mylibs} -lpq -L$(pg_config --libdir)"
	fi

	if use sqlite ; then
		mycc="${mycc} -DHAS_SQLITE"
		mylibs="${mylibs} -lsqlite3"
	fi

	if use ssl ; then
		mycc="${mycc} -DUSE_TLS"
		mylibs="${mylibs} -lssl -lcrypto"
	fi

	if use sasl ; then
		if use dovecot-sasl ; then
			# Set dovecot as default.
			mycc="${mycc} -DDEF_SASL_SERVER=\\\"dovecot\\\""
		fi
		if use ldap-bind ; then
			mycc="${mycc} -DUSE_LDAP_SASL"
		fi
		mycc="${mycc} -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl"
		mylibs="${mylibs} -lsasl2"
	elif use dovecot-sasl ; then
		mycc="${mycc} -DUSE_SASL_AUTH -DDEF_SERVER_SASL_TYPE=\\\"dovecot\\\""
	fi

	if ! use nis ; then
		sed -i -e "s|#define HAS_NIS|//#define HAS_NIS|g" \
			src/util/sys_defs.h || die "sed failed"
	fi

	if use cdb ; then
		mycc="${mycc} -DHAS_CDB -I/usr/include/cdb"
		CDB_LIBS=""

		# Tinycdb is preferred.
		if has_version dev-db/tinycdb ; then
			einfo "Building with dev-db/tinycdb"
			CDB_LIBS="-lcdb"
		else
			einfo "Building with dev-db/cdb"
			CDB_PATH="/usr/$(get_libdir)"
			for i in cdb.a alloc.a buffer.a unix.a byte.a ; do
				CDB_LIBS="${CDB_LIBS} ${CDB_PATH}/${i}"
			done
		fi

		mylibs="${mylibs} ${CDB_LIBS}"
	fi

	mycc="${mycc} -DDEF_DAEMON_DIR=\\\"/usr/$(get_libdir)/postfix\\\""
	mycc="${mycc} -DDEF_CONFIG_DIR=\\\"/etc/postfix\\\""
	mycc="${mycc} -DDEF_COMMAND_DIR=\\\"/usr/sbin\\\""
	mycc="${mycc} -DDEF_SENDMAIL_PATH=\\\"/usr/sbin/sendmail\\\""
	mycc="${mycc} -DDEF_NEWALIS_PATH=\\\"/usr/bin/newaliases\\\""
	mycc="${mycc} -DDEF_MAILQ_PATH=\\\"/usr/bin/mailq\\\""
	mycc="${mycc} -DDEF_MANPAGE_DIR=\\\"/usr/share/man\\\""
	mycc="${mycc} -DDEF_README_DIR=\\\"/usr/share/doc/${PF}/readme\\\""
	mycc="${mycc} -DDEF_HTML_DIR=\\\"/usr/share/doc/${PF}/html\\\""
	mycc="${mycc} -DDEF_QUEUE_DIR=\\\"/var/spool/postfix\\\""
	mycc="${mycc} -DDEF_DATA_DIR=\\\"/var/lib/postfix\\\""
	mycc="${mycc} -DDEF_MAIL_OWNER=\\\"postfix\\\""
	mycc="${mycc} -DDEF_SGID_GROUP=\\\"postdrop\\\""

	# Robin H. Johnson <robbat2@gentoo.org> 17/Nov/2006
	# Fix because infra boxes hit 2Gb .db files that fail a 32-bit fstat signed check.
	mycc="${mycc} -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE"
	filter-lfs-flags

	# Workaround for bug #76512
	if use hardened ; then
		[[ "$(gcc-version)" == "3.4" ]] && replace-flags -O? -Os
	fi

	emake DEBUG="" CC="$(tc-getCC)" OPT="${CFLAGS}" CCARGS="${mycc}" AUXLIBS="${mylibs}" makefiles
}

src_install () {
	/bin/sh postfix-install \
		-non-interactive \
		install_root="${D}" \
		config_directory="/etc/postfix" \
		manpage_directory="/usr/share/man" \
		readme_directory="/usr/share/doc/${PF}/readme" \
		html_directory="/usr/share/doc/${PF}/html" \
		command_directory="/usr/sbin" \
		daemon_directory="/usr/$(get_libdir)/postfix" \
		mailq_path="/usr/bin/mailq" \
		newaliases_path="/usr/bin/newaliases" \
		sendmail_path="/usr/sbin/sendmail" \
		|| die "postfix-install failed"

	# Fix spool removal on upgrade
	rm -Rf "${D}"/var
	keepdir /var/spool/postfix

	# Install rmail for UUCP, closes bug #19127
	dobin auxiliary/rmail/rmail

	# Provide another link for legacy FSH
	dosym /usr/sbin/sendmail /usr/$(get_libdir)/sendmail

	# Install qshape tool
	dobin auxiliary/qshape/qshape.pl
	doman man/man1/qshape.1

	# Performance tuning tools and their manuals
	dosbin bin/smtp-{source,sink} bin/qmqp-{source,sink}
	doman man/man1/smtp-{source,sink}.1 man/man1/qmqp-{source,sink}.1

	# Set proper permissions on required files/directories
	dodir /var/lib/postfix
	keepdir /var/lib/postfix
	fowners postfix:postfix /var/lib/postfix
	fowners postfix:postfix /var/lib/postfix/.keep_${CATEGORY}_${PN}-${SLOT}
	fperms 0750 /var/lib/postfix
	fowners root:postdrop /usr/sbin/post{drop,queue}
	fperms 02711 /usr/sbin/post{drop,queue}

	keepdir /etc/postfix
	if use mbox ; then
		mypostconf="mail_spool_directory=/var/spool/mail"
	else
		mypostconf="home_mailbox=.maildir/"
	fi
	"${D}"/usr/sbin/postconf -c "${D}"/etc/postfix \
		-e ${mypostconf} || die "postconf failed"

	insinto /etc/postfix
	newins "${FILESDIR}"/smtp.pass saslpass
	fperms 600 /etc/postfix/saslpass

	newinitd "${FILESDIR}"/postfix.rc6.${RC_VER} postfix
	# bug #359913
	use mysql || sed -i -e "s/mysql //" "${D}/etc/init.d/postfix"
	use postgres || sed -i -e "s/postgresql //" "${D}/etc/init.d/postfix"

	dodoc *README COMPATIBILITY HISTORY PORTING RELEASE_NOTES*

	mv "${S}"/examples "${D}"/usr/share/doc/${PF}/
	mv "${D}"/etc/postfix/{*.default,makedefs.out} "${D}"/usr/share/doc/${PF}/

	pamd_mimic_system smtp auth account

	if use sasl ; then
		insinto /etc/sasl2
		newins "${FILESDIR}"/smtp.sasl smtpd.conf
	fi

	# Remove unnecessary files
	rm -f "${D}"/etc/postfix/{*LICENSE,access,aliases,canonical,generic}
	rm -f "${D}"/etc/postfix/{header_checks,relocated,transport,virtual}
}

pkg_postinst() {
	# Do not install server.{key,pem) SSL certificates if they already exist
	if use ssl && [[ ! -f "${ROOT}"/etc/ssl/postfix/server.key \
		&& ! -f "${ROOT}"/etc/ssl/postfix/server.pem ]] ; then
		SSL_ORGANIZATION="${SSL_ORGANIZATION:-Postfix SMTP Server}"
		install_cert /etc/ssl/postfix/server
		chown postfix:mail "${ROOT}"/etc/ssl/postfix/server.{key,pem}
	fi
}
