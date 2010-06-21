# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/openrc/openrc-0.3.0-r1.ebuild,v 1.1 2008/10/08 16:19:11 cardoe Exp $

inherit eutils flag-o-matic multilib toolchain-funcs

SRC_URI="http://www.funtoo.org/archive/openrc/openrc-funtoo-2009.11.18.tar.bz2"
DESCRIPTION="OpenRC manages the services, startup and shutdown of a host"
HOMEPAGE="http://roy.marples.name/openrc"
PROVIDE="virtual/baselayout"
RESTRICT="nomirror"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
IUSE="debug ncurses pam unicode kernel_linux kernel_FreeBSD"

RDEPEND="kernel_linux? ( >=sys-apps/sysvinit-2.86-r11 )
	kernel_FreeBSD? ( virtual/init sys-process/fuser-bsd )
	elibc_glibc? ( >=sys-libs/glibc-2.5 )
	ncurses? ( sys-libs/ncurses )
	pam? ( virtual/pam )
	>=sys-apps/baselayout-2.0.0
	>=sys-fs/udev-135"
DEPEND="ncurses? ( sys-libs/ncurses ) eclibc_glibc? ( >=sys-libs/glibc-2.5 ) pam? ( virtual/pam ) virtual/os-headers"
S="$WORKDIR/openrc"

pkg_setup() {
	LIBDIR="lib"
	[ "${SYMLINK_LIB}" = "yes" ] && LIBDIR=$(get_abi_LIBDIR "${DEFAULT_ABI}")

	MAKE_ARGS="${MAKE_ARGS} LIBNAME=${LIBDIR}"

	local brand="Unknown"
	if use kernel_linux ; then
		MAKE_ARGS="${MAKE_ARGS} OS=Linux"
		brand="Linux"
	elif use kernel_FreeBSD ; then
		MAKE_ARGS="${MAKE_ARGS} OS=FreeBSD"
		brand="FreeBSD"
	fi
	export BRANDING="Funtoo ${brand}"

	export DEBUG=$(usev debug)
	export MKPAM=$(usev pam)
	export MKTERMCAP=$(usev ncurses)
}

src_compile() {
	cd $S; echo $S
	# catch people running `ebuild` w/out setup
	if [[ -z ${MAKE_ARGS} ]] ; then
		die "Your MAKE_ARGS is empty ... are you running 'ebuild' but forgot to execute 'setup' ?"
	fi

	sed -i "/^VERSION[[:space:]]*=/s:=.*:=${PV}:" Makefile

	tc-export CC AR RANLIB
	echo emake ${MAKE_ARGS}
	emake ${MAKE_ARGS} || die "emake ${MAKE_ARGS} failed"
}

src_install() {
	emake ${MAKE_ARGS} DESTDIR="${D}" install || die "make install failed"
	gen_usr_ldscript libeinfo.so
	gen_usr_ldscript librc.so

	dodir /etc/runlevels/default

	keepdir /"${LIBDIR}"/rc/init.d
	keepdir /"${LIBDIR}"/rc/tmp

	# Backup our default runlevels
	dodir /usr/share/"${PN}"
	mv "${D}/etc/runlevels" "${D}/usr/share/${PN}"
	
	# Setup unicode defaults for silly unicode users
	use unicode && sed -i -e '/^.*unicode=/s:^.*"NO":unicode="YES":' "${D}"/etc/rc.conf

	# Cater to the norm
	(use x86 || use amd64) && sed -i -e '/^.*windowkeys=/s:^.*"NO":windowkeys="YES":' "${D}"/etc/conf.d/keymaps
}

add_init() {
	local runl=$1
	shift
	if [ ! -e ${ROOT}/etc/runlevels/${runl} ]
	then
		install -d -m0755 ${ROOT}/etc/runlevels/${runl}
	fi
	for initd in $*
	do
		[[ -e ${ROOT}/etc/runlevels/${runl}/${initd} ]] && continue
		elog "Auto-adding '${initd}' service to your ${runl} runlevel"
		ln -snf /etc/init.d/${initd} "${ROOT}"/etc/runlevels/${runl}/${initd}
	done
}

pkg_postinst() {
	local runl
	install -d -m0755 ${ROOT}/etc/runlevels
	local runldir="${ROOT}usr/share/${PN}/runlevels"

	# Remove old baselayout links
	rm -f "${ROOT}"/etc/runlevels/boot/{check{fs,root},rmnologin}

	# CREATE RUNLEVEL DIRECTORIES	
	# ===========================

	# To ensure proper system operation, this portion of the script ensures that
	# all of OpenRC's default initscripts in all runlevels are properly
	# installed.

	for runl in $( cd "$runldir"; echo * )
	do
		einfo "Processing $runl..."
		einfo "Ensuring runlevel $runl has all required scripts..."
		add_init $runl $( cd "$runldir/$runl"; echo * )
	done

	# Rather than try to migrate everyone using complex scripts, simply print
	# names of initscripts that are in the user's runlevels but not provided by
	# OpenRC. This loop can be upgraded to look for particular scripts that
	# might have come from baselayout.

	for runl in $( cd ${ROOT}/etc/runlevels; echo * )
	do
		for init in $( cd $runl; echo * )
		do
			if [ -e ${ROOT}/etc/runlevels/${runl}/${init} ] && [ ! -e ${runldir}/${runl}/${init} ]
			then
				echo "Initscript ${init} exists in runlevel ${runl} but not in
				OpenRC."
			fi
		done
	done

	# OTHER STUFF
	# ===========

	# update the dependency tree bug #224171
	[[ "${ROOT}" = "/" ]] && "${ROOT}/libexec"/rc/bin/rc-depend -u

	elog "You should now update all files in /etc, using etc-update"
	elog "or equivalent before rebooting."
	elog
	
	#if [ -e $ROOTetc/conf.d/net ]
	#then
	#	ewarn "IMPORTANT: your funtoo networking scripts will need to"
	#	ewarn "be upgraded."
	#	ewarn
	#	ewarn "Please read the Funtoo Networking Guide at"
	#	ewarn "http://www.funtoo.org/en/funtoo/networking/"
	#	ewarn
	#	ewarn "(This message triggered by existence of $ROOTetc/conf.d/net.)"
	#fi
}
