# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/pam/pam-1.1.1-r2.ebuild,v 1.13 2010/10/22 08:01:02 flameeyes Exp $

EAPI="3"

inherit libtool multilib eutils autotools pam toolchain-funcs flag-o-matic db-use

MY_PN="Linux-PAM"
MY_P="${MY_PN}-${PV}"

HOMEPAGE="http://www.kernel.org/pub/linux/libs/pam/"
DESCRIPTION="Linux-PAM (Pluggable Authentication Modules)"

SRC_URI="mirror://kernel/linux/libs/pam/library/${MY_P}.tar.bz2
	mirror://kernel/linux/libs/pam/documentation/${MY_P}-docs.tar.bz2"

LICENSE="|| ( BSD GPL-2 )"
SLOT="0"
KEYWORDS="alpha amd64 arm ~hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-linux ~ia64-linux ~x86-linux"
IUSE="cracklib nls elibc_FreeBSD selinux vim-syntax audit test elibc_glibc debug berkdb"

RDEPEND="nls? ( virtual/libintl )
	cracklib? ( >=sys-libs/cracklib-2.8.3 )
	audit? ( sys-process/audit )
	selinux? ( >=sys-libs/libselinux-1.28 )
	berkdb? ( sys-libs/db )
	elibc_glibc? ( >=sys-libs/glibc-2.7 )"
DEPEND="${RDEPEND}
	sys-devel/flex
	nls? ( sys-devel/gettext )"
PDEPEND="sys-auth/pambase
	vim-syntax? ( app-vim/pam-syntax )"
RDEPEND="${RDEPEND}
	!sys-auth/pam_userdb"

S="${WORKDIR}/${MY_P}"

PROVIDE="virtual/pam"

check_old_modules() {
	local retval="0"

	if sed -e 's:#.*::' "${EROOT}"/etc/pam.d/* 2>/dev/null | fgrep -q pam_stack.so; then
		eerror ""
		eerror "Your current setup is using the pam_stack module."
		eerror "This module is deprecated and no longer supported, and since version"
		eerror "0.99 is no longer installed, nor provided by any other package."
		eerror "The package will be built (to allow binary package builds), but will"
		eerror "not be installed."
		eerror "Please replace pam_stack usage with proper include directive usage,"
		eerror "following the PAM Upgrade guide at the following URL"
		eerror "  http://www.gentoo.org/proj/en/base/pam/upgrade-0.99.xml"
		eerror ""

		retval=1
	fi

	if sed -e 's:#.*::' "${EROOT}"/etc/pam.d/* 2>/dev/null | egrep -q 'pam_(pwdb|console)'; then
		eerror ""
		eerror "Your current setup is using one or more of the following modules,"
		eerror "that are not built or supported anymore:"
		eerror "pam_pwdb, pam_console"
		eerror "If you are in real need for these modules, please contact the maintainers"
		eerror "of PAM through http://bugs.gentoo.org/ providing information about its"
		eerror "use cases."
		eerror "Please also make sure to read the PAM Upgrade guide at the following URL:"
		eerror "  http://www.gentoo.org/proj/en/base/pam/upgrade-0.99.xml"
		eerror ""

		retval=1
	fi

	return $retval
}

pkg_setup() {
	check_old_modules
}

src_prepare() {
	# Avoid building xtests during "make all"; note that for what
	# we're concerned xtests are not even executed, so we should
	# probably use EXTRA_PROGRAMS.
	epatch "${FILESDIR}/${MY_PN}-0.99.8.1-xtests.patch"

	# Fix building on uClibc; it is added since 1.1.1 but applies to
	# 1.1.0 as well.
	epatch "${FILESDIR}/${MY_PN}-1.1.0-uclibc.patch"

	# Fix tests to find Berkeley DB as installed by Gentoo (with a
	# library suffix but no suffix on the ELF symbols).
	epatch "${FILESDIR}/${MY_PN}-1.1.1-gentoodb.patch"

	# make it possible to skip libxcrypt detection if header is not
	# found
	epatch "${FILESDIR}/${MY_PN}-1.1.1-xcrypt.patch"

	# fix building with Berkeley DB 5.0 and later; now defining
	# DB_DBM_HSEARCH is not enough; bug #319831
	epatch "${FILESDIR}/${MY_PN}-1.1.1+berkdb-5.patch"

	# fix tally file created executable, see bug #329885
	epatch "${FILESDIR}/${MY_PN}-1.1.1-pam_tally2-mode.patch"

	# Remove libtool-2 libtool macros, see bug 261167
	rm m4/libtool.m4 m4/lt*.m4 || die "rm libtool macros failed."

	eautoreconf

	elibtoolize
}

src_configure() {
	local myconf

	if use hppa || use elibc_FreeBSD; then
		myconf="${myconf} --disable-pie"
	fi

	# Disable automatic detection of libxcrypt; we _don't_ want the
	# user to link libxcrypt in by default, since we won't track the
	# dependency and allow to break PAM this way.
	export ac_cv_header_xcrypt_h=no

	econf \
		--libdir="${EPREFIX}"/usr/$(get_libdir) \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		--htmldir="${EPREFIX}"/usr/share/doc/${PF}/html \
		--enable-securedir="${EPREFIX}"/$(get_libdir)/security \
		--enable-isadir="${EPREFIX}"/$(get_libdir)/security \
		$(use_enable nls) \
		$(use_enable selinux) \
		$(use_enable cracklib) \
		$(use_enable audit) \
		$(use_enable debug) \
		$(use_enable berkdb db) \
		--with-db-uniquename=-$(db_findver sys-libs/db) \
		--disable-dependency-tracking \
		--disable-prelude \
		${myconf}
}

src_compile() {
	emake sepermitlockdir="${EPREFIX}/var/run/sepermit" || die "emake failed"
}

src_test() {
	# explicitly allow parallel-build during testing
	emake sepermitlockdir="${EPREFIX}/var/run/sepermit" check || die "emake check failed"
}

src_install() {
	local lib

	emake DESTDIR="${D}" install \
		 sepermitlockdir="${EPREFIX}/var/run/sepermit" || die "make install failed"

	# Need to be suid
	fperms u+s /sbin/unix_chkpwd

	gen_usr_ldscript -a pam pamc pam_misc

	# create extra symlinks just in case something depends on them...
	for lib in pam pamc pam_misc; do
		if ! [[ -f "${ED}"/$(get_libdir)/lib${lib}$(get_libname) ]]; then
			dosym lib${lib}$(get_libname 0) /$(get_libdir)/lib${lib}$(get_libname)
		fi
	done

	dodoc CHANGELOG ChangeLog README AUTHORS Copyright NEWS || die

	docinto modules
	for dir in modules/pam_*; do
		newdoc "${dir}"/README README."$(basename "${dir}")"
	done

	# Get rid of the .la files. We certainly don't need them for PAM
	# modules, and libpam is installed as a shared object only, so we
	# don't need them for static linking either.
	find "${D}" -name '*.la' -delete
}

pkg_preinst() {
	check_old_modules || die "deprecated PAM modules still used"
}

pkg_postinst() {
	ewarn "Some software with pre-loaded PAM libraries might experience"
	ewarn "warnings or failures related to missing symbols and/or versions"
	ewarn "after any update. While unfortunate this is a limit of the"
	ewarn "implementation of PAM and the software, and it requires you to"
	ewarn "restart the software manually after the update."
	ewarn ""
	ewarn "You can get a list of such software running a command like"
	ewarn "  lsof / | egrep 'DEL.*libpam\\.so'"
	elog ""
	elog "Because of a bug present up to version 1.1.1-r2, you might have"
	elog "an executable /var/log/tallylog file. If it is so, you can safely"
	elog "correct it by running the command"
	elog "  chmod -x /var/log/tallylog"
	elog ""
}
