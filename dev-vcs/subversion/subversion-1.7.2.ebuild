# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-vcs/subversion/subversion-1.7.1.ebuild,v 1.2 2011/11/30 14:28:49 grobian Exp $

EAPI="3"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="3.* *-jython"
WANT_AUTOMAKE="none"
MY_P="${P/_/-}"

inherit autotools base bash-completion db-use depend.apache elisp-common flag-o-matic java-pkg-opt-2 libtool multilib perl-module python

DESCRIPTION="Advanced version control system"
HOMEPAGE="http://subversion.apache.org/"
SRC_URI="http://www.apache.org/dist/${PN}/${MY_P}.tar.bz2"
S="${WORKDIR}/${MY_P}"

LICENSE="Subversion"
SLOT="0"
KEYWORDS="~*"
IUSE="apache2 berkdb ctypes-python debug doc +dso extras gnome-keyring java kde nls perl python ruby sasl vim-syntax +webdav-neon webdav-serf"

CDEPEND=">=dev-db/sqlite-3.4
	>=dev-libs/apr-1.3:1
	>=dev-libs/apr-util-1.3:1
	dev-libs/expat
	sys-libs/zlib
	berkdb? ( >=sys-libs/db-4.0.14 )
	ctypes-python? ( =dev-lang/python-2* )
	gnome-keyring? ( dev-libs/glib:2 sys-apps/dbus gnome-base/gnome-keyring )
	kde? ( sys-apps/dbus x11-libs/qt-core x11-libs/qt-dbus x11-libs/qt-gui >=kde-base/kdelibs-4 )
	perl? ( dev-lang/perl )
	python? ( =dev-lang/python-2* )
	ruby? ( >=dev-lang/ruby-1.8.2 )
	sasl? ( dev-libs/cyrus-sasl )
	webdav-neon? ( >=net-libs/neon-0.28 )
	webdav-serf? ( >=net-libs/serf-0.3.0 )"
RDEPEND="${CDEPEND}
	apache2? ( www-servers/apache[apache2_modules_dav] )
	java? ( >=virtual/jre-1.5 )
	kde? ( kde-base/kwalletd )
	nls? ( virtual/libintl )
	perl? ( dev-perl/URI )"
DEPEND="${CDEPEND}
	!!<sys-apps/sandbox-1.6
	ctypes-python? ( dev-python/ctypesgen )
	doc? ( app-doc/doxygen )
	gnome-keyring? ( dev-util/pkgconfig )
	java? ( >=virtual/jdk-1.5 )
	kde? ( dev-util/pkgconfig )
	nls? ( sys-devel/gettext )
	webdav-neon? ( dev-util/pkgconfig )"

PATCHES=(
		"${FILESDIR}/${PN}-1.5.4-interix.patch"
		"${FILESDIR}/${PN}-1.5.6-aix-dso.patch"
		"${FILESDIR}/${PN}-1.6.3-hpux-dso.patch"
		"${FILESDIR}/${PN}-1.6.17-swig-perl-depend.patch"
)

want_apache

pkg_setup() {
	if use berkdb; then
		local apu_bdb_version="$(${EPREFIX}/usr/bin/apu-1-config --includes \
			| grep -Eoe '-I${EPREFIX}/usr/include/db[[:digit:]]\.[[:digit:]]' \
			| sed 's:.*b::')"
		einfo
		if [[ -z "${SVN_BDB_VERSION}" ]]; then
			if [[ -n "${apu_bdb_version}" ]]; then
				SVN_BDB_VERSION="${apu_bdb_version}"
				einfo "Matching db version to apr-util"
			else
				SVN_BDB_VERSION="$(db_ver_to_slot "$(db_findver sys-libs/db 2>/dev/null)")"
				einfo "SVN_BDB_VERSION variable isn't set. You can set it to enforce using of specific version of Berkeley DB."
			fi
		fi
		einfo "Using: Berkeley DB ${SVN_BDB_VERSION}"
		einfo

		if [[ -n "${apu_bdb_version}" && "${SVN_BDB_VERSION}" != "${apu_bdb_version}" ]]; then
			eerror "APR-Util is linked against Berkeley DB ${apu_bdb_version}, but you are trying"
			eerror "to build Subversion with support for Berkeley DB ${SVN_BDB_VERSION}."
			eerror "Rebuild dev-libs/apr-util or set SVN_BDB_VERSION=\"${apu_bdb_version}\"."
			eerror "Aborting to avoid possible run-time crashes."
			die "Berkeley DB version mismatch"
		fi
	fi

	depend.apache_pkg_setup

	java-pkg-opt-2_pkg_setup

	if use ctypes-python || use python; then
		python_pkg_setup
	fi

	if ! use webdav-neon && ! use webdav-serf; then
		ewarn "WebDAV support is disabled. You need WebDAV to"
		ewarn "access repositories through the HTTP protocol."
		ewarn "Consider enabling one of the following USE-flags:"
		ewarn "  webdav-neon webdav-serf"
		echo -ne "\a"
	fi

	if use debug; then
		append-cppflags -DSVN_DEBUG -DAP_DEBUG
	fi

	# Allow for custom repository locations.
	SVN_REPOS_LOC="${SVN_REPOS_LOC:-${EPREFIX}/var/svn}"
}

src_prepare() {
	base_src_prepare
	fperms +x build/transform_libtool_scripts.sh

	sed -i \
		-e "s/\(BUILD_RULES=.*\) bdb-test\(.*\)/\1\2/g" \
		-e "s/\(BUILD_RULES=.*\) test\(.*\)/\1\2/g" configure.ac

	sed -e "/SWIG_PY_INCLUDES=/s/\$ac_cv_python_includes/\\\\\$(PYTHON_INCLUDES)/" -i build/ac-macros/swig.m4 || die "sed failed"

	# this bites us in particular on Solaris
	sed -i -e '1c\#!/usr/bin/env sh' build/transform_libtool_scripts.sh || \
		die "/bin/sh is not POSIX shell!"

	eautoconf
	elibtoolize

	sed -e "s/libsvn_swig_py-1\.la/libsvn_swig_py-\$(PYTHON_VERSION)-1.la/" -i build-outputs.mk || die "sed failed"
}

src_configure() {
	local myconf

	if use python || use perl || use ruby; then
		myconf+=" --with-swig"
	else
		myconf+=" --without-swig"
	fi

	if use java; then
		myconf+=" --without-junit"
	fi

	if use kde || use nls; then
		myconf+=" --enable-nls"
	else
		myconf+=" --disable-nls"
	fi

	case ${CHOST} in
		*-solaris*)
			# -lintl isn't added for some reason (makes Neon check fail)
			use nls && append-libs -lintl
		;;
		*-aix*)
			# avoid recording immediate path to sharedlibs into executables
			append-ldflags -Wl,-bnoipath
		;;
		*-interix*)
			# loader crashes on the LD_PRELOADs...
			myconf="${myconf} --disable-local-library-preloading"
		;;
	esac

	econf --libdir="${EPREFIX}/usr/$(get_libdir)" \
		$(use_with apache2 apxs "${APXS}") \
		$(use_with berkdb berkeley-db "db.h:${EPREFIX}/usr/include/db${SVN_BDB_VERSION}::db-${SVN_BDB_VERSION}") \
		$(use_with ctypes-python ctypesgen "${EPREFIX}/usr") \
		$(use_enable dso runtime-module-search) \
		$(use_with gnome-keyring) \
		$(use_enable java javahl) \
		$(use_with java jdk "${JAVA_HOME}") \
		$(use_with kde kwallet) \
		$(use_with sasl) \
		$(use_with webdav-neon neon) \
		$(use_with webdav-serf serf "${EPREFIX}/usr") \
		${myconf} \
		--with-apr="${EPREFIX}/usr/bin/apr-1-config" \
		--with-apr-util="${EPREFIX}/usr/bin/apu-1-config" \
		--disable-experimental-libtool \
		--without-jikes \
		--enable-local-library-preloading \
		--disable-mod-activation \
		--disable-neon-version-check \
		--disable-static \
		--with-sqlite="${EPREFIX}/usr"
}

src_compile() {
	emake local-all || die "Building of core of Subversion failed"

	if use ctypes-python; then
		python_copy_sources subversion/bindings/ctypes-python
		rm -fr subversion/bindings/ctypes-python
		ctypes_python_bindings_building() {
			rm -f subversion/bindings/ctypes-python
			ln -s ctypes-python-${PYTHON_ABI} subversion/bindings/ctypes-python
			emake ctypes-python
		}
		python_execute_function \
			--action-message 'Building of Subversion Ctypes Python bindings with $(python_get_implementation) $(python_get_version)' \
			--failure-message 'Building of Subversion Ctypes Python bindings failed with $(python_get_implementation) $(python_get_version)' \
			ctypes_python_bindings_building
	fi

	if use python; then
		python_copy_sources subversion/bindings/swig/python
		rm -fr subversion/bindings/swig/python
		swig_python_bindings_building() {
			rm -f subversion/bindings/swig/python
			ln -s python-${PYTHON_ABI} subversion/bindings/swig/python
			emake \
				PYTHON_INCLUDES="-I${EPREFIX}$(python_get_includedir)" \
				PYTHON_VERSION="$(python_get_version)" \
				swig_pydir="${EPREFIX}$(python_get_sitedir)/libsvn" \
				swig_pydir_extra="${EPREFIX}$(python_get_sitedir)/svn" \
				swig-py
		}
		python_execute_function \
			--action-message 'Building of Subversion SWIG Python bindings with $(python_get_implementation) $(python_get_version)' \
			--failure-message 'Building of Subversion SWIG Python bindings failed with $(python_get_implementation) $(python_get_version)' \
			swig_python_bindings_building
	fi

	if use perl; then
		emake swig-pl || die "Building of Subversion SWIG Perl bindings failed"
	fi

	if use ruby; then
		emake swig-rb || die "Building of Subversion SWIG Ruby bindings failed"
	fi

	if use java; then
		emake -j1 JAVAC_FLAGS="$(java-pkg_javac-args) -encoding iso8859-1" javahl || die "Building of Subversion JavaHL library failed"
	fi

	if use extras; then
		emake tools || die "Building of tools failed"
	fi

	if use doc; then
		doxygen doc/doxygen.conf || die "Building of Subversion HTML documentation failed"

		if use java; then
			emake doc-javahl || die "Building of Subversion JavaHL library HTML documentation failed"
		fi
	fi
}

src_install() {
	emake -j1 DESTDIR="${D}" local-install || die "Installation of core of Subversion failed"

	if use ctypes-python; then
		ctypes_python_bindings_installation() {
			rm -f subversion/bindings/ctypes-python
			ln -s ctypes-python-${PYTHON_ABI} subversion/bindings/ctypes-python
			emake DESTDIR="${D}" install-ctypes-python
		}
		python_execute_function \
			--action-message 'Installation of Subversion Ctypes Python bindings with $(python_get_implementation) $(python_get_version)' \
			--failure-message 'Installation of Subversion Ctypes Python bindings failed with $(python_get_implementation) $(python_get_version)' \
			ctypes_python_bindings_installation
	fi

	if use python; then
		swig_python_bindings_installation() {
			rm -f subversion/bindings/swig/python
			ln -s python-${PYTHON_ABI} subversion/bindings/swig/python
			emake \
				DESTDIR="${D}" \
				PYTHON_VERSION="$(python_get_version)" \
				swig_pydir="${EPREFIX}$(python_get_sitedir)/libsvn" \
				swig_pydir_extra="${EPREFIX}$(python_get_sitedir)/svn" \
				install-swig-py
		}
		python_execute_function \
			--action-message 'Installation of Subversion SWIG Python bindings with $(python_get_implementation) $(python_get_version)' \
			--failure-message 'Installation of Subversion SWIG Python bindings failed with $(python_get_implementation) $(python_get_version)' \
			swig_python_bindings_installation
	fi

	if use ctypes-python || use python; then
		python_clean_installation_image -q
	fi

	if use perl; then
		emake DESTDIR="${D}" INSTALLDIRS="vendor" install-swig-pl || die "Installation of Subversion SWIG Perl bindings failed"
		fixlocalpod
		find "${ED}" "(" -name .packlist -o -name "*.bs" ")" -print0 | xargs -0 rm -fr
	fi

	if use ruby; then
		emake DESTDIR="${D}" install-swig-rb || die "Installation of Subversion SWIG Ruby bindings failed"
	fi

	if use java; then
		emake DESTDIR="${D}" install-javahl || die "Installation of Subversion JavaHL library failed"
		java-pkg_regso "${ED}"usr/$(get_libdir)/libsvnjavahl*$(get_libname)
		java-pkg_dojar "${ED}"usr/$(get_libdir)/svn-javahl/svn-javahl.jar
		rm -fr "${ED}"usr/$(get_libdir)/svn-javahl/*.jar
	fi

	# Install Apache module configuration.
	if use apache2; then
		keepdir "${APACHE_MODULES_CONFDIR}"
		insinto "${APACHE_MODULES_CONFDIR}"
		doins "${FILESDIR}/47_mod_dav_svn.conf"
	fi

	# Install Bash Completion, bug 43179.
	dobashcompletion tools/client-side/bash_completion subversion
	rm -f tools/client-side/bash_completion

	# Install hot backup script, bug 54304.
	newbin tools/backup/hot-backup.py svn-hot-backup
	rm -fr tools/backup

	# Install svnserve init-script and xinet.d snippet, bug 43245.
	newinitd "${FILESDIR}"/svnserve.initd2 svnserve
	newconfd "${FILESDIR}"/svnserve.confd svnserve
	insinto /etc/xinetd.d
	newins "${FILESDIR}"/svnserve.xinetd svnserve

	# Install documentation.
	dodoc CHANGES COMMITTERS README
	dodoc tools/xslt/svnindex.{css,xsl}
	rm -fr tools/xslt

	# Install extra files.
	if use extras; then
		cat << EOF > 80subversion-extras
PATH="${EPREFIX}/usr/$(get_libdir)/subversion/bin"
ROOTPATH="${EPREFIX}/usr/$(get_libdir)/subversion/bin"
EOF
		doenvd 80subversion-extras

		emake DESTDIR="${D}" toolsdir="/usr/$(get_libdir)/subversion/bin" install-tools || die "Installation of tools failed"

		find tools "(" -name "*.bat" -o -name "*.in" -o -name ".libs" ")" -print0 | xargs -0 rm -fr
		rm -fr tools/client-side/svnmucc
		rm -fr tools/server-side/{svn-populate-node-origins-index,svnauthz-validate}*
		rm -fr tools/{buildbot,dev,diff,po}

		insinto /usr/share/${PN}
		doins -r tools
	fi

	if use doc; then
		dohtml -r doc/doxygen/html/* || die "Installation of Subversion HTML documentation failed"

		dodoc notes/*

		if use java; then
			java-pkg_dojavadoc doc/javadoc
		fi
	fi

	find "${D}" '(' -name '*.la' ')' -print0 | xargs -0 rm -f
}

pkg_preinst() {
	# Compare versions of Berkeley DB, bug 122877.
	if use berkdb && [[ -f "${EROOT}usr/bin/svn" ]]; then
		OLD_BDB_VERSION="$(scanelf -nq "${EROOT}usr/$(get_libdir)/libsvn_subr-1$(get_libname 0)" | grep -Eo "libdb-[[:digit:]]+\.[[:digit:]]+" | sed -e "s/libdb-\(.*\)/\1/")"
		NEW_BDB_VERSION="$(scanelf -nq "${ED}usr/$(get_libdir)/libsvn_subr-1$(get_libname 0)" | grep -Eo "libdb-[[:digit:]]+\.[[:digit:]]+" | sed -e "s/libdb-\(.*\)/\1/")"
		if [[ "${OLD_BDB_VERSION}" != "${NEW_BDB_VERSION}" ]]; then
			CHANGED_BDB_VERSION="1"
		fi
	fi
}

pkg_postinst() {
	use perl && perl-module_pkg_postinst

	if use ctypes-python; then
		python_mod_optimize csvn
	fi

	if use python; then
		python_mod_optimize libsvn svn
	fi

	if [[ -n "${CHANGED_BDB_VERSION}" ]]; then
		ewarn "You upgraded from an older version of Berkeley DB and may experience"
		ewarn "problems with your repository. Run the following commands as root to fix it:"
		ewarn "    db4_recover -h ${SVN_REPOS_LOC}/repos"
		ewarn "    chown -Rf apache:apache ${SVN_REPOS_LOC}/repos"
	fi

	ewarn "If you run subversion as a daemon, you will need to restart it to avoid module mismatches."
}

pkg_postrm() {
	use perl && perl-module_pkg_postrm

	if use ctypes-python; then
		python_mod_cleanup csvn
	fi

	if use python; then
		python_mod_cleanup libsvn svn
	fi
}

pkg_config() {
	# Remember: Don't use ${EROOT}${SVN_REPOS_LOC} since ${SVN_REPOS_LOC}
	# already has EPREFIX in it
	einfo "Initializing the database in ${ROOT}${SVN_REPOS_LOC}..."
	if [[ -e "${ROOT}${SVN_REPOS_LOC}/repos" ]]; then
		echo "A Subversion repository already exists and I will not overwrite it."
		echo "Delete \"${ROOT}${SVN_REPOS_LOC}/repos\" first if you're sure you want to have a clean version."
	else
		mkdir -p "${ROOT}${SVN_REPOS_LOC}/conf"

		einfo "Populating repository directory..."
		# Create initial repository.
		"${EROOT}usr/bin/svnadmin" create "${ROOT}${SVN_REPOS_LOC}/repos"

		einfo "Setting repository permissions..."
		SVNSERVE_USER="$(. "${EROOT}etc/conf.d/svnserve"; echo "${SVNSERVE_USER}")"
		SVNSERVE_GROUP="$(. "${EROOT}etc/conf.d/svnserve"; echo "${SVNSERVE_GROUP}")"
		if use apache2; then
			[[ -z "${SVNSERVE_USER}" ]] && SVNSERVE_USER="apache"
			[[ -z "${SVNSERVE_GROUP}" ]] && SVNSERVE_GROUP="apache"
		else
			[[ -z "${SVNSERVE_USER}" ]] && SVNSERVE_USER="svn"
			[[ -z "${SVNSERVE_GROUP}" ]] && SVNSERVE_GROUP="svnusers"
			enewgroup "${SVNSERVE_GROUP}"
			enewuser "${SVNSERVE_USER}" -1 -1 "${SVN_REPOS_LOC}" "${SVNSERVE_GROUP}"
		fi
		chown -Rf "${SVNSERVE_USER}:${SVNSERVE_GROUP}" "${ROOT}${SVN_REPOS_LOC}/repos"
		chmod -Rf go-rwx "${ROOT}${SVN_REPOS_LOC}/conf"
		chmod -Rf o-rwx "${ROOT}${SVN_REPOS_LOC}/repos"
	fi
}
