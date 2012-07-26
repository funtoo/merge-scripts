# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit eutils

MAJOR_VER="${PV:0:3}"
MINOR_VER="${PV:4:1}"
BUILD_NUM="33735"
SRC_DIR="LogitechMediaServer_v${PV}"
MY_P="logitechmediaserver-${PV}-noCPAN"
MY_P_BUILD_NUM="logitechmediaserver-${MAJOR_VER}.${MINOR_VER}-${BUILD_NUM}-noCPAN"

DESCRIPTION="Logitech SqueezeboxServer music server"
HOMEPAGE="http://www.mysqueezebox.com/download"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~*"
IUSE="lame wavpack ogg flac aac"

# Note: EV present because of bug#287857.
SRC_URI="http://downloads.slimdevices.com/${SRC_DIR}/${MY_P}.tgz"

# Note: common-sense currently required due to bundled EV (Gentoo bug#287257)
DEPEND="
	!media-sound/squeezecenter
	!prefix? ( virtual/logger )
	virtual/mysql
	>=dev-perl/common-sense-2.01
	"
# Note: dev-perl/GD necessary because of SC bug#6143
# (http://bugs.slimdevices.com/show_bug.cgi?id=6143).
RDEPEND="
	!prefix? ( >=sys-apps/baselayout-2.0.0 )
	dev-perl/File-Which
	!prefix? ( virtual/logger )
	virtual/mysql
	>=dev-lang/perl-5.8.8
	~dev-perl/Audio-Scan-0.930.0
	>=dev-perl/GD-2.41
	>=virtual/perl-IO-Compress-2.015
	>=dev-perl/YAML-Syck-1.05
	>=dev-perl/DBD-mysql-4.00.5
	>=dev-perl/DBI-1.607
	>=dev-perl/Digest-SHA1-2.11
	>=dev-perl/Encode-Detect-1.01
	>=dev-perl/HTML-Parser-3.56
	>=dev-perl/JSON-XS-2.2.3.1
	>=dev-perl/Template-Toolkit-2.19
	>=virtual/perl-Time-HiRes-1.97.15
	>=dev-perl/XML-Parser-2.36
	>=dev-perl/Cache-Cache-1.04
	>=dev-perl/Class-Data-Inheritable-0.08
	>=dev-perl/Class-Inspector-1.23
	>=dev-perl/File-Next-1.02
	>=virtual/perl-File-Temp-0.20
	>=dev-perl/File-Which-0.05
	>=perl-core/i18n-langtags-0.35
	>=dev-perl/IO-String-1.08
	>=dev-perl/Log-Log4perl-1.13
	>=dev-perl/libwww-perl-5.805
	>=perl-core/CGI-3.29
	>=dev-perl/TimeDate-1.16
	>=dev-perl/Math-VecStat-0.08
	>=dev-perl/Net-DNS-0.63
	>=dev-perl/Path-Class-0.16
	>=dev-perl/SQL-Abstract-1.56
	>=dev-perl/SQL-Abstract-Limit-0.12
	>=dev-perl/URI-1.35
	>=dev-perl/XML-Simple-2.18
	>=perl-core/version-0.76
	>=dev-perl/Carp-Clan-5.9
	>=dev-perl/Readonly-1.03
	>=dev-perl/Carp-Assert-0.20
	>=dev-perl/Class-Virtual-0.06
	>=dev-perl/File-Slurp-9999.13
	>=dev-perl/Exporter-Lite-0.02
	>=dev-perl/Tie-IxHash-1.21
	>=virtual/perl-Module-Pluggable-3.6
	>=dev-perl/Archive-Zip-1.23
	~dev-perl/AnyEvent-5.2.5.1
	>=dev-perl/Sub-Name-0.04
	>=dev-perl/Module-Find-0.08
	>=dev-perl/Class-Accessor-0.31
	>=dev-perl/Class-XSAccessor-1.05
	>=dev-perl/AutoXS-Header-1.02
	>=dev-perl/Scope-Guard-0.03
	>=dev-perl/Class-C3-XS-0.13
	>=dev-perl/Class-C3-0.21
	>=dev-perl/Class-C3-Componentised-1.0.800
	>=dev-perl/File-ReadBackwards-1.04
	~dev-perl/DBIx-Class-0.08120
	>=dev-perl/JSON-XS-VersionOneAndTwo-0.31
	>=dev-perl/MRO-Compat-0.11
	>=dev-perl/PAR-0.994
	>=dev-perl/enum-1.016
	>=dev-perl/URI-Find-20100211
	>=dev-perl/Algorithm-C3-0.08
	>=dev-perl/Text-Unidecode-0.04
	>=dev-perl/Net-UPnP-1.4.2
	>=dev-perl/File-BOM-0.14
	>=dev-perl/Proc-Background-1.10
	>=dev-perl/Tie-Cache-LRU-20081023.2116
	>=dev-perl/Tie-Cache-LRU-Expires-0.54
	>=dev-perl/Data-Dump-1.15
	>=dev-perl/Data-Page-2.02
	>=dev-perl/Data-URIEncode-0.11
	>=dev-perl/Tie-LLHash-1.003
	>=dev-perl/Tie-RegexpHash-0.15
	>=dev-perl/Data-UUID-1.202
	>=dev-perl/Image-Scale-0.08
	>=dev-perl/YAML-LibYAML-0.37
	>=dev-perl/DBD-SQLite-1.34
	>=dev-perl/EV-4.03
	>=perl-core/Class-ISA-0.36
	lame? ( media-sound/lame )
	wavpack? ( media-sound/wavpack )
	flac? (
		media-libs/flac
		media-sound/sox[flac]
		)
	ogg? ( media-sound/sox[ogg] )
	aac? ( media-libs/faad2 )
	"

S="${WORKDIR}/${MY_P_BUILD_NUM}"

ETCDIR="/etc/logitechmediaserver"
PREFS="${ETCDIR}/logitechmediaserver.prefs"
PREFSDIR="${ETCDIR}/prefs"
PREFS2="${PREFSDIR}/server.prefs"
DOCDIR="/usr/share/doc/logitechmediaserver-${PV}"
SHAREDIR="/usr/share/logitechmediaserver"
LIBDIR="/usr/$(get_libdir)/logitechmediaserver"
OLDDBUSER="squeezecenter"
DBUSER="logitechmediaserver"
VARLIBSBS="/var/lib/logitechmediaserver"
PLUGINSDIR="${VARLIBSBS}/Plugins"

# To support Migration
OLDETCDIR="/etc/squeezecenter"
OLDPREFSDIR="/var/lib/squeezecenter/prefs"
OLDPREFSFILE="${OLDPREFSDIR}/server.prefs"
OLDPLUGINSDIR="/var/lib/squeezecenter/Plugins"
MIGMARKER=".migrated"

pkg_setup() {
	# Create the user and group if not already present
	enewgroup logitechmediaserver
	enewuser logitechmediaserver -1 -1 "/dev/null" logitechmediaserver
}

src_prepare() {
	# Apply patches
	#epatch "${FILESDIR}/${P}-build-perl-modules-gentoo.patch"
	epatch "${FILESDIR}/${P}-uuid-gentoo.patch"

	# Copy in the module builder - can't run it from the files directory in case
	# Portage is mounted 'noexec'.
#	cp "${FILESDIR}/build-modules-${PV}.sh" "${S}/build-modules.sh"	|| die
#	chmod 555 "${S}/build-modules.sh"			|| die
}

src_install() {

	# The main Perl executables
	exeinto /usr/sbin
	newexe slimserver.pl logitechmediaserver		|| die "Failed to install server executable"
	newexe scanner.pl logitechmediaserver-scanner	|| die "Failed to install scanner executable"
	newexe cleanup.pl logitechmediaserver-cleanup	|| die "Failed to install cleanup executable"

	# The custom OS module for Gentoo - provides OS-specific path details
	cp "${FILESDIR}/gentoo-filepaths.pm" "Slim/Utils/OS/Custom.pm" || die "Unable to install Gentoo custom OS module"

	# The server Perl modules
	local installvendorlib
	eval `perl '-V:installvendorlib'`
	dodir "${installvendorlib#${EPREFIX}}"
	cp -r Slim "${D}${installvendorlib}" || die "Unable to install server Perl modules"

	# Various directories of architecture-independent static files
	dodir "${SHAREDIR}"
	cp -r Firmware "${ED}/${SHAREDIR}"		|| die "Unable to install Firmware"
	cp -r Graphics "${ED}/${SHAREDIR}"		|| die "Unable to install Graphics"
	cp -r HTML "${ED}/${SHAREDIR}"			|| die "Unable to install HTML"
	cp -r IR "${ED}/${SHAREDIR}"			|| die "Unable to install IR"
	cp -r SQL "${ED}/${SHAREDIR}"			|| die "Unable to install SQL"

	# Architecture-dependent static files
	dodir "${LIBDIR}"
	cp -r lib/* "${ED}${LIBDIR}" || die "Unable to install architecture-dependent files"
	dodir "${LIBDIR}"/CPAN
	cp -r CPAN/Media ${ED}/${LIBDIR}/CPAN || die "Unable to install Media"

	# Install compiled Perl modules because of bug#287857.
	#dodir "${LIBDIR}/CPAN/arch"
	#mv perl-modules/*/*/*/* "${ED}${LIBDIR}/CPAN/arch" || die "Unable to install compiled CPAN modules"

	# Strings and version identification
	insinto "${SHAREDIR}"
	doins strings.txt
	doins revision.txt

	# Documentation
	dodoc Changelog*.html
	dodoc Installation.txt
	dodoc License*.txt
	dodoc "${FILESDIR}/Gentoo-plugins-README.txt"
	dodoc "${FILESDIR}/Gentoo-detailed-changelog.txt"

	# Configuration files and preferences
	insinto "${ETCDIR}"
	doins convert.conf
	doins types.conf
	doins modules.conf
	newins "${FILESDIR}/logitechmediaserver.prefs" logitechmediaserver.prefs

	# Preferences directory
	dodir "${PREFSDIR}"
	fowners logitechmediaserver:logitechmediaserver "${PREFSDIR}"
	fperms 770 "${PREFSDIR}"

	# Install init scripts
	newconfd "${FILESDIR}/logitechmediaserver.conf.d" logitechmediaserver
	newinitd "${FILESDIR}/logitechmediaserver.init.d" logitechmediaserver

	# Install the SQL configuration scripts
	insinto "${SHAREDIR}/SQL/mysql"
	doins "${FILESDIR}/dbdrop-gentoo.sql"
	doins "${FILESDIR}/dbcreate-gentoo.sql"

	# Initialize run directory (where the PID file lives)
	dodir /var/run/logitechmediaserver
	fowners logitechmediaserver:logitechmediaserver /var/run/logitechmediaserver
	fperms 770 /var/run/logitechmediaserver

	# Initialize server cache directory
	dodir /var/lib/logitechmediaserver/cache
	fowners logitechmediaserver:logitechmediaserver /var/lib/logitechmediaserver/cache
	fperms 770 /var/lib/logitechmediaserver/cache

	# Initialize the log directory
	dodir /var/log/logitechmediaserver
	fowners logitechmediaserver:logitechmediaserver /var/log/logitechmediaserver
	fperms 770 /var/log/logitechmediaserver
	touch "${ED}/var/log/logitechmediaserver/server.log"
	touch "${ED}/var/log/logitechmediaserver/scanner.log"
	touch "${ED}/var/log/logitechmediaserver/perfmon.log"
	fowners logitechmediaserver:logitechmediaserver /var/log/logitechmediaserver/server.log
	fowners logitechmediaserver:logitechmediaserver /var/log/logitechmediaserver/scanner.log
	fowners logitechmediaserver:logitechmediaserver /var/log/logitechmediaserver/perfmon.log

	# Initialise the user-installed plugins directory
	dodir "${PLUGINSDIR}"
	fowners logitechmediaserver:logitechmediaserver "${PLUGINSDIR}"
	fperms 770 "${PLUGINSDIR}"

	# Install logrotate support
	insinto /etc/logrotate.d
	newins "${FILESDIR}/logitechmediaserver.logrotate.d" logitechmediaserver
}

sc_starting_instr() {
	elog "Squeezebox Server can be started with the following command:"
	elog "\t/etc/init.d/logitechmediaserver start"
	elog ""
	elog "Squeezebox Server can be automatically started on each boot with the"
	elog "following command:"
	elog "\trc-update add logitechmediaserver default"
	elog ""
	elog "You might want to examine and modify the following configuration"
	elog "file before starting Squeezebox Server:"
	elog "\t/etc/conf.d/logitechmediaserver"
	elog ""

	# Discover the port number from the preferences, but if it isn't there
	# then report the standard one.
	httpport=$(gawk '$1 == "httpport:" { print $2 }' "${ROOT}${LIVE_PREFS}" 2>/dev/null)
	elog "You may access and configure Squeezebox Server by browsing to:"
	elog "\thttp://localhost:${httpport:-9000}/"
}

pkg_postinst() {
	# FLAC and LAME are quite useful (but not essential) for Squeezebox Server -
	# if they're not enabled then make sure the user understands that.
	if ! use flac; then
		ewarn "'flac' USE flag is not set.  Although not essential, FLAC is required"
		ewarn "for playing lossless WAV and FLAC (for Squeezebox 1), and for"
		ewarn "playing other less common file types (if you have a Squeezebox 2 or newer)."
		ewarn "For maximum flexibility you are recommended to set the 'flac' USE flag".
		ewarn ""
	fi
	if ! use lame; then
		ewarn "'lame' USE flag is not set.  Although not essential, LAME is"
		ewarn "required if you want to limit the bandwidth your Squeezebox or"
		ewarn "Transporter uses when streaming audio."
		ewarn "For maximum flexibility you are recommended to set the 'lame' USE flag".
		ewarn ""
	fi

	# Album art requires PNG and JPEG support from GD, so if it's not there
	# then warn the user.  It's not mandatory as the user may not be using
	# album art.
	if ! has_version dev-perl/GD[jpeg] || \
	   ! has_version dev-perl/GD[png] || \
	   ! has_version media-libs/gd[jpeg] || \
	   ! has_version media-libs/gd[png]; then
		ewarn "For correct operation of album art through Squeezebox Server's web"
		ewarn "interface the GD library and Perl module must be built with PNG"
		ewarn "and JPEG support.  If necessary you can add the following lines"
		ewarn "to the file /etc/portage/package.use:"
		ewarn "\tdev-perl/GD jpeg png"
		ewarn "\tmedia-libs/gd jpeg png"
		ewarn "And then rebuild those packages with:"
		ewarn "\temerge --newuse dev-perl/GD media-libs/gd"
		ewarn ""
	fi

	# Point user to database configuration step
	elog "If this is a new installation of Squeezebox Server then the database"
	elog "must be configured prior to use.  This can be done by running the"
	elog "following command:"
	elog "\temerge --config =${CATEGORY}/${PF}"
	elog "This command will also migrate old SqueezeCenter preferences and"
	elog "plugins (if present)."

	elog ""

	ewarn "Note: If Squeezebox Server dies after the initial configuration"
	ewarn "      after an upgrade from a previous installation, try removing"
	ewarn "      /var/lib/logitechmediaserver and /etc/logitechmediaserver and"
	ewarn "      then reinstalling the package (note that old preferences"
	ewarn "      and plugins will be lost).  See bug #307119."

	elog ""

	sc_starting_instr
}

sc_remove_db_prefs() {
	MY_PREFS=$1

	einfo "Configuring Squeezebox Server database preferences (${MY_PREFS}) ..."
	TMPPREFS="${T}"/logitechmediaserver-prefs-$$
	touch "${EROOT}${MY_PREFS}"
	sed -e '/^dbusername:/d' -e '/^dbpassword:/d' -e '/^dbsource:/d' < "${EROOT}${MY_PREFS}" > "${TMPPREFS}"
	mv "${TMPPREFS}" "${EROOT}${MY_PREFS}"
	chown logitechmediaserver:logitechmediaserver "${EROOT}${MY_PREFS}"
	chmod 660 "${EROOT}${MY_PREFS}"
}

sc_update_prefs() {
	MY_PREFS=$1
	MY_DBUSER=$2
	MY_DBUSER_PASSWD=$3

	echo "dbusername: ${MY_DBUSER}" >> "${EROOT}${MY_PREFS}"
	echo "dbpassword: ${MY_DBUSER_PASSWD}" >> "${EROOT}${MY_PREFS}"
	echo "dbsource: dbi:mysql:database=${MY_DBUSER};mysql_socket=${EPREFIX}/var/run/mysqld/mysqld.sock" >> "${EROOT}${MY_PREFS}"
}

pkg_config() {
	einfo "Press ENTER to create the Squeezebox Server database and set proper"
	einfo "permissions on it.  You will be prompted for the MySQL 'root' user's"
	einfo "password during this process (note that the MySQL 'root' user is"
	einfo "independent of the Linux 'root' user and so may have a different"
	einfo "password)."
	einfo ""
	einfo "If you already have a Squeezebox Server database set up then this"
	einfo "process will clear the existing database (your music files will not,"
	einfo "however, be affected)."
	einfo ""
	einfo "Alternatively, press Control-C to abort now..."
	read

	# Get the MySQL root password from the user (not echoed to the terminal)
	einfo "The MySQL 'root' user password is required to create the"
	einfo "Squeezebox Server user and database."
	DONE=0
	while [ $DONE -eq 0 ]; do
		trap "stty echo; echo" EXIT
		stty -echo
		read -p "MySQL root password: " ROOT_PASSWD; echo
		stty echo
		trap ":" EXIT
		echo quit | mysql --user=root --password="${ROOT_PASSWD}" >/dev/null 2>&1 && DONE=1
		if [ $DONE -eq 0 ]; then
			eerror "Incorrect MySQL root password, or MySQL is not running"
		fi
	done

	# Get the new password for the Squeezebox Server MySQL database user, and
	# have it re-entered to confirm it.  We should trivially check it's not
	# the same as the MySQL root password.
	einfo "A new MySQL user will be added to own the Squeezebox Server database."
	einfo "Please enter the password for this new user (${DBUSER})."
	DONE=0
	while [ $DONE -eq 0 ]; do
		trap "stty echo; echo" EXIT
		stty -echo
		read -p "MySQL ${DBUSER} password: " DBUSER_PASSWD; echo
		stty echo
		trap ":" EXIT
		if [ -z "$DBUSER_PASSWD" ]; then
			eerror "The password should not be blank; try again."
		elif [ "$DBUSER_PASSWD" == "$ROOT_PASSWD" ]; then
			eerror "The ${DBUSER} password should be different to the root password"
		else
			DONE=1
		fi
	done

	# Drop the existing database and user - note we don't care about errors
	# from this as it probably just indicates that the database wasn't
	# yet present.
	einfo "Dropping old Squeezebox Server database and user ..."
	sed -e "s/__DATABASE__/${DBUSER}/" -e "s/__DBUSER__/${DBUSER}/" < "${EPREFIX}${SHAREDIR}/SQL/mysql/dbdrop-gentoo.sql" | mysql --user=root --password="${ROOT_PASSWD}" >/dev/null 2>&1

	# Drop and create the Squeezebox Server user and database.
	einfo "Creating Squeezebox Server MySQL user and database (${DBUSER}) ..."
	sed -e "s/__DATABASE__/${DBUSER}/" -e "s/__DBUSER__/${DBUSER}/" -e "s/__DBPASSWORD__/${DBUSER_PASSWD}/" < "${EPREFIX}${SHAREDIR}/SQL/mysql/dbcreate-gentoo.sql" | mysql --user=root --password="${ROOT_PASSWD}" || die "Unable to create MySQL database and user"

	# Migrate old preferences, if present.
	if [ -d "${OLDPREFSFILE}" ]; then
		if [ -f "${ETCDIR}/${MIGMARKER}" ]; then
			einfo ""
			einfo "Old preferences are present, but they appear to have been"
			einfo "migrated before. If you would like to re-migrate the old"
			einfo "SqueezeCenter preferences remove the following file, and"
			einfo "then restart the configuration."
			einfo "\t${ETCDIR}/${MIGMARKER}"
		else
			einfo "Migrating old SqueezeCenter preferences"
			cp -r "${OLDPREFSDIR}" "${VARLIBSBS}"
			mv "${VARLIBSBS}/prefs/server.prefs" "/etc/logitechmediaserver/logitechmediaserver.prefs"
			chown -R logitechmediaserver:logitechmediaserver "${PREFSDIR}"
			touch "${PREFSDIR}/${MIGMARKER}"
		fi
	fi

	# Migrate old plugins, if present.
	if [ -d "${OLDPLUGINSDIR}" ]; then
		if [ -f "${PLUGINSDIR}/${MIGMARKER}" ]; then
			einfo ""
			einfo "Old plugins are present, but they appear to have been"
			einfo "migrated before. If you would like to re-migrate the old"
			einfo "SqueezeCenter preferences remove the following file, and"
			einfo "then restart the configuration."
			einfo "\t${PLUGINSDIR}/${MIGMARKER}"
		else
			einfo "Migrating old SqueezeCenter plugins"
			cp -r "${OLDPLUGINSDIR}" "${VARLIBSBS}"
			chown -R logitechmediaserver:logitechmediaserver "${PLUGINSDIR}"
			touch "${PLUGINSDIR}/${MIGMARKER}"
		fi
	fi

	# Remove the existing MySQL preferences from Squeezebox Server (if any).
	sc_remove_db_prefs "${PREFS}"
	sc_remove_db_prefs "${PREFS2}"

	# Insert the external MySQL configuration into the preferences.
	sc_update_prefs "${PREFS}" "${DBUSER}" "${DBUSER_PASSWD}"
	sc_update_prefs "${PREFS2}" "${DBUSER}" "${DBUSER_PASSWD}"

	# Phew - all done. Give some tips on what to do now.
	einfo "Database configuration complete."
	einfo ""
	sc_starting_instr
}

pkg_preinst() {
	# Warn the user if there are old preferences that may need migrating.
	if [ -d "${OLDPREFSDIR}" -a ! -f "${PREFSDIR}/${MIGMARKER}" ]; then
		if [ ! -z "$(ls ${OLDPREFSDIR})" ]; then
			ewarn "Note: It appears that old SqueezeCenter preferences are
installed at:"
			ewarn "\t${OLDPREFSDIR}"
			ewarn "These may be migrated by running the following command:"
			ewarn "\temerge --config =${CATEGORY}/${PF}"
			ewarn "(Please note that this will require your music collection to
be rescanned.)"
			ewarn ""
		fi
	fi
}
