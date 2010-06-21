# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-db/postgresql-server/postgresql-server-8.1.20.ebuild,v 1.2 2010/04/25 20:26:01 armin76 Exp $

EAPI="2"

WANT_AUTOMAKE="none"
inherit eutils multilib toolchain-funcs versionator autotools

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~s390 ~sh ~sparc ~x86"

DESCRIPTION="PostgreSQL server"
HOMEPAGE="http://www.postgresql.org/"
SRC_URI="mirror://postgresql/source/v${PV}/postgresql-${PV}.tar.bz2"
LICENSE="POSTGRESQL"
SLOT="$(get_version_component_range 1-2)"
IUSE_LINGUAS="
	linguas_af linguas_cs linguas_de linguas_es linguas_fa linguas_fr
	linguas_hr linguas_hu linguas_it linguas_ko linguas_nb linguas_pl
	linguas_pt_BR linguas_ro linguas_ru linguas_sk linguas_sl linguas_sv
	linguas_tr linguas_zh_CN linguas_zh_TW"
IUSE="doc perl python selinux tcl xml nls kernel_linux ${IUSE_LINGUAS}"

wanted_languages() {
	for u in ${IUSE_LINGUAS} ; do
		use $u && echo -n "${u#linguas_} "
	done
}

RDEPEND="~dev-db/postgresql-base-${PV}:${SLOT}
	perl? ( >=dev-lang/perl-5.6.1-r2 )
	python? ( >=dev-lang/python-2.2 dev-python/egenix-mx-base )
	selinux? ( sec-policy/selinux-postgresql )
	tcl? ( >=dev-lang/tcl-8 )
	xml? ( dev-libs/libxml2 dev-libs/libxslt )"
DEPEND="${RDEPEND}
	sys-devel/flex
	xml? ( dev-util/pkgconfig )"
PDEPEND="doc? ( ~dev-db/postgresql-docs-${PV} )"

S="${WORKDIR}/postgresql-${PV}"

pkg_setup() {
	enewgroup postgres 70
	enewuser postgres 70 /bin/bash /var/lib/postgresql postgres
}

src_prepare() {

	epatch "${FILESDIR}/postgresql-${SLOT}-common.patch" \
		"${FILESDIR}/postgresql-${SLOT}-server.patch"

	if use test; then
		sed -e "s|/no/such/location|${S}/src/test/regress/tmp_check/no/such/location|g" -i src/test/regress/{input,output}/tablespace.source
	fi

	eautoconf
}

src_configure() {
	# TODO: test if PPC really cannot work with other CFLAGS settings
	# use ppc && CFLAGS="-pipe -fsigned-char"

	# eval is needed to get along with pg_config quotation of space-rich entities.
	eval econf "$(/usr/$(get_libdir)/postgresql-${SLOT}/bin/pg_config --configure)" \
		$(use_with perl) \
		$(use_with python) \
		$(use_with tcl) \
		--with-includes="/usr/include/postgresql-${SLOT}/" \
		"$(has_version ~dev-db/postgresql-base-${PV}[nls] && use_enable nls nls "$(wanted_languages)")" \
		|| die "configure failed"
}

src_compile() {
	for bd in . contrib $(use xml && echo contrib/xml2) ; do
		PATH="/usr/$(get_libdir)/postgresql-${SLOT}/bin:${PATH}" \
			emake -C $bd -j1 LD="$(tc-getLD) $(get_abi_LDFLAGS)" \
				PGXS=$(/usr/$(get_libdir)/postgresql-${SLOT}/bin/pg_config --pgxs) \
				NO_PGXS=0 USE_PGXS=1 docdir=/usr/share/doc/${PF} || die "emake in $bd failed"
	done
}

src_install() {
	if use perl ; then
		mv -f "${S}/src/pl/plperl/GNUmakefile" "${S}/src/pl/plperl/GNUmakefile_orig"
		sed -e "s:\$(DESTDIR)\$(plperl_installdir):\$(plperl_installdir):" \
			"${S}/src/pl/plperl/GNUmakefile_orig" > "${S}/src/pl/plperl/GNUmakefile"
	fi

	for bd in . contrib $(use xml && echo contrib/xml2) ; do
		PATH="/usr/$(get_libdir)/postgresql-${SLOT}/bin:${PATH}" \
			emake install -C $bd -j1 DESTDIR="${D}" \
				PGXS=$(/usr/$(get_libdir)/postgresql-${SLOT}/bin/pg_config --pgxs) \
				NO_PGXS=0 USE_PGXS=1 docdir=/usr/share/doc/${PF} || die "emake install in $bd failed"
	done

	rm -rf "${D}/usr/share/postgresql-${SLOT}/man/man7/" "${D}/usr/share/doc/${PF}/html"
	rm "${D}"/usr/share/postgresql-${SLOT}/man/man1/{clusterdb,create{db,lang,user},drop{db,lang,user},ecpg,pg_{config,dump,dumpall,restore},psql,reindexdb,vacuumdb}.1

	dodoc README HISTORY doc/{README.*,TODO,bug.template}

	dodir /etc/eselect/postgresql/slots/${SLOT}
	cat >"${D}/etc/eselect/postgresql/slots/${SLOT}/service" <<-__EOF__
		postgres_ebuilds="\${postgres_ebuilds} ${PF}"
		postgres_service="postgresql-${SLOT}"
	__EOF__

	newinitd "${FILESDIR}/postgresql.init-${SLOT}" postgresql-${SLOT} || die "Inserting init.d-file failed"
	newconfd "${FILESDIR}/postgresql.conf-${SLOT}" postgresql-${SLOT} || die "Inserting conf.d-file failed"

	keepdir /var/run/postgresql
	fperms 0770 /var/run/postgresql
	fowners postgres:postgres /var/run/postgresql
}

pkg_postinst() {
	eselect postgresql update
	[[ "$(eselect postgresql show)" = "(none)" ]] && eselect postgresql set ${SLOT}
	[[ "$(eselect postgresql show-service)" = "(none)" ]] && eselect postgresql set-service ${SLOT}

	ewarn "Please note that the standard location of the socket has changed from /tmp"
	ewarn "to /var/run/postgresql and you have to be in the 'postgres' group to access"
	ewarn "the socket."
	ewarn "This can break applications which have the standard location hard-coded."
	ewarn "If such an application links against the libpq, please re-emerge it,"
	ewarn "if that doesn't help or the application accesses the socket without using libpq,"
	ewarn "please file a bug-report."
	ewarn "You can set PGOPTS='-k /tmp' in /etc/conf.d/postgresql-${SLOT} to restore the original location."

	elog "Execute the following command to setup the initial database environment:"
	elog
	elog "emerge --config =${CATEGORY}/${PF}"
	elog
	elog "The autovacuum function, which was in contrib, has been moved to the main"
	elog "PostgreSQL functions starting with 8.1."
	elog "You can enable it in the clusters postgresql.conf."
}

pkg_postrm() {
	eselect postgresql update
}

pkg_config() {
	[[ -f /etc/conf.d/postgresql-${SLOT} ]] && source /etc/conf.d/postgresql-${SLOT}
	[[ -z "${PGDATA}" ]] && PGDATA="/var/lib/postgresql/${SLOT}/data"

	if [ -z "${PG_INITDB_OPTS}" ]; then
		if [ -f /etc/env.d/02locale ]; then
			source /etc/env.d/02locale
			[ -n "${LC_ALL}" ] &&
				PG_INITDB_OPTS="--locale=$LC_ALL"
			[ -n "${LC_COLLATE}" -a "${LC_COLLATE}" != "${LC_ALL}" ] &&
				PG_INITDB_OPTS="${PG_INITDB_OPTS} --lc-collate=${LC_COLLATE}"
			[ -n "${LC_CTYPE}" -a "${LC_CTYPE}" != "${LC_ALL}" ] &&
				PG_INITDB_OPTS="${PG_INITDB_OPTS} --lc-ctype=${LC_CTYPE}"
			[ -n "${LC_MESSAGES}" -a "${LC_MESSAGES}" != "${LC_ALL}" ] &&
				PG_INITDB_OPTS="${PG_INITDB_OPTS} --lc-messages=${LC_MESSAGES}"
			[ -n "${LC_MONETARY}" -a "${LC_MONETARY}" != "${LC_ALL}" ] &&
				PG_INITDB_OPTS="${PG_INITDB_OPTS} --lc-monetary=${LC_MONETARY}"
			[ -n "${LC_NUMERIC}" -a "${LC_MONETARY}" != "${LC_ALL}" ] &&
				PG_INITDB_OPTS="${PG_INITDB_OPTS} --lc-numeric=${LC_NUMERIC}"
			[ -n "${LC_TIME}" -a "${LC_TIME}" != "${LC_ALL}" ] &&
				PG_INITDB_OPTS="${PG_INITDB_OPTS} --lc-time=${LC_TIME}"
		fi
		if [ -n "$PG_INITDB_OPTS" ]; then
			einfo "Locale info set from /etc/env.d/02locale"
		else
			eerror "You must set PG_INITDB_OPTS in /etc/conf.d/postgresql-${SLOT}"
			eerror "    More knfo: http://www.postgresql.org/docs/${SLOT}/static/locale.html"
			eerror "Or, you must localize this system."
			eerror "    More info: http://www.gentoo.org/doc/en/guide-localization.xml"
			die "No locale variables found."
		fi
	else
		einfo "PG_INITDB_OPTS set in /etc/conf.d/postgresql-${SLOT}"
	fi

	# Matches C, POSIX, or locale codes as described in "locale -a"
	# This could probably use a little work, but is sufficient.
	MATCHSTRING="([cC]|[pP][oO][sS][iI][xX]|[a-z][a-z]_[A-Z][A-Z]\.[[:alnum:]_-]+)"
	# Test that at the very least --locale is present as it sets the default
	# locale and encoding to be used for the server. If not, check to make sure
	# the other six variables are set.
	if [[ $PG_INITDB_OPTS =~ .*--locale=$MATCHSTRING ]] || (
			[[ "${PG_INITDB_OPTS}" =~ .*--lc-collate=$MATCHSTRING ]] &&
			[[ "${PG_INITDB_OPTS}" =~ .*--lc-ctype=$MATCHSTRING ]] &&
			[[ "${PG_INITDB_OPTS}" =~ .*--lc-messages=$MATCHSTRING ]] &&
			[[ "${PG_INITDB_OPTS}" =~ .*--lc-monetary=$MATCHSTRING ]] &&
			[[ "${PG_INITDB_OPTS}" =~ .*--lc-numeric=$MATCHSTRING ]] &&
			[[ "${PG_INITDB_OPTS}" =~ .*--lc-time=$MATCHSTRING ]]
		); then
		einfo "Locale settings look okay."
	else
		eerror "PG_INITDB_OPTS was set in /etc/conf.d/postgresql-${SLOT}"
		eerror "Or, locales were found in /etc/env.d/02locale"
		eerror "But, a satisfying match was not found."
		die "No locale information found or character set not specified."
	fi

	einfo "You can pass options to initdb by setting the PG_INITDB_OPTS variable."
	einfo "More information can be found here:"
	einfo "    http://www.postgresql.org/docs/${SLOT}/static/creating-cluster.html"
	einfo "    http://www.postgresql.org/docs/${SLOT}/static/app-initdb.html"
	einfo "Simply add the options you would have added to initdb to the PG_INITDB_OPTS variable."
	einfo
	einfo "You can change the directory where the database cluster is being created by setting"
	einfo "the PGDATA variable."
	einfo
	einfo "PG_INITDB_OPTS is currently set to:"
	einfo "    \"${PG_INITDB_OPTS}\""
	einfo "and the database cluster will be created in:"
	einfo "    \"${PGDATA}\""
	einfo "Are you ready to continue? (Y/n)"
	read answer
	[ -z $answer ] && answer=Y
	[ "$answer" == "Y" ] || [ "$answer" == "y" ] || die "aborted"

	if [[ -f "${PGDATA}/PG_VERSION" ]] ; then
		eerror "The given directory \"${PGDATA}\" already contains a database cluster."
		die "cluster already exists"
	fi

	[ -z "${PG_MAX_CONNECTIONS}" ] && PG_MAX_CONNECTIONS="128"
	einfo "Checking system parameters..."

	if ! use kernel_linux ; then
		SKIP_SYSTEM_TESTS=yes
		einfo "  Tests not supported on this OS (yet)"
	fi

	if [ -z ${SKIP_SYSTEM_TESTS} ] ; then
		einfo "Checking whether your system supports at least ${PG_MAX_CONNECTIONS} connections..."

		local SEMMSL=$(sysctl -n kernel.sem | cut -f1)
		local SEMMNS=$(sysctl -n kernel.sem | cut -f2)
		local SEMMNI=$(sysctl -n kernel.sem | cut -f4)
		local SHMMAX=$(sysctl -n kernel.shmmax)

		local SEMMSL_MIN=17
		local SEMMNS_MIN=$(( ( ${PG_MAX_CONNECTIONS}/16 ) * 17 ))
		local SEMMNI_MIN=$(( ( ${PG_MAX_CONNECTIONS}+15 ) / 16 ))
		local SHMMAX_MIN=$(( 500000 + ( 30600 * ${PG_MAX_CONNECTIONS} ) ))

		for p in SEMMSL SEMMNS SEMMNI SHMMAX ; do
			if [ $(eval echo \$$p) -lt $(eval echo \$${p}_MIN) ] ; then
				eerror "The value for ${p} $(eval echo \$$p) is below the recommended value $(eval echo \$${p}_MIN)"
				eerror "You have now several options:"
				eerror "  - Change the mentioned system parameter"
				eerror "  - Lower the number of max.connections by setting PG_MAX_CONNECTIONS to a value lower than ${PG_MAX_CONNECTIONS}"
				eerror "  - Set SKIP_SYSTEM_TESTS in case you want to ignore this test completely"
				eerror "More information can be found here:"
				eerror "  http://www.postgresql.org/docs/${SLOT}/static/kernel-resources.html"
				die "System test failed."
			fi
		done
		einfo "Passed."
	else
		einfo "Skipped."
	fi

	einfo "Creating the data directory ..."
	mkdir -p "${PGDATA}"
	chown -Rf postgres:postgres "${PGDATA}"
	chmod 0700 "${PGDATA}"

	einfo "Initializing the database ..."

	su postgres -c "/usr/$(get_libdir)/postgresql-${SLOT}/bin/initdb --pgdata \"${PGDATA}\" ${PG_INITDB_OPTS}"

	einfo
	einfo "You can use the '${ROOT}/etc/init.d/postgresql-${SLOT}' script to run PostgreSQL instead of 'pg_ctl'."
	einfo

	if [ "${PGDATA}" != "/var/lib/postgresql/${SLOT}/data" ] ; then
		ewarn "You didn't install the database cluster in the standard location, please make sure that you set"
		ewarn "PGDATA=\"${PGDATA}\" in the appropriate conf.d file (probably /etc/conf.d/postgresql-${SLOT})"
	fi
}

src_test() {
	einfo ">>> Test phase [check]: ${CATEGORY}/${PF}"
	PATH="/usr/$(get_libdir)/postgresql-${SLOT}/bin:${PATH}" \
		emake -j1 check \
			PGXS=$(/usr/$(get_libdir)/postgresql-${SLOT}/bin/pg_config --pgxs) \
			NO_PGXS=0 USE_PGXS=1 SLOT=${SLOT} || die "Make check failed. See above for details."

	einfo "Yes, there are other tests which could be run."
	einfo "... and no, we don't plan to add/support them."
	einfo "For now, the main regressions tests will suffice."
	einfo "If you think other tests are necessary, please submit a"
	einfo "bug including a patch for this ebuild to enable them."
}
