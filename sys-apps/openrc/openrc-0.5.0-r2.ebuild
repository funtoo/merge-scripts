# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/openrc/openrc-0.3.0-r1.ebuild,v 1.1 2008/10/08 16:19:11 cardoe Exp $

inherit eutils flag-o-matic multilib toolchain-funcs

SRC_URI="http://www.funtoo.org/archive/openrc/openrc-funtoo-2009.08.01.tar.bz2"
DESCRIPTION="OpenRC manages the services, startup and shutdown of a host"
HOMEPAGE="http://roy.marples.name/openrc"
PROVIDE="virtual/baselayout"
RESTRICT="nomirror"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc sparc-fbsd x86 x86-fbsd"
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
	
	#Install special patch to apply later
	insinto /usr/share/${PN}/misc
	doins ${FILESDIR}/inittab-openrc.patch
	
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

add_init_mit_config() {
	# DESCRIPTION: if config file exists and isn't just comments and blank lines, then install our initscript.
	local runl=$1 config=$2 initd=$3
	if [[ -e ${ROOT}${config} ]] ; then
		if [[ -n $(sed -e 's:#.*::' -e '/^[[:space:]]*$/d' "${ROOT}"/${config}) ]] ; then
			add_init ${runl} ${initd}
		fi
	fi
}

pkg_preinst() {
	local f

	# upgrade timezone file ... do it before moving clock
	if [[ -e ${ROOT}/etc/conf.d/clock && ! -e ${ROOT}/etc/timezone ]] ; then
		(
		source "${ROOT}"/etc/conf.d/clock
		[[ -n ${TIMEZONE} ]] && echo "${TIMEZONE}" > "${ROOT}"/etc/timezone
		)
	fi

	# /etc/conf.d/clock moved to /etc/conf.d/hwclock
	local clock
	use kernel_FreeBSD && clock="adjkerntz" || clock="hwclock"
	if [[ -e ${ROOT}/etc/conf.d/clock ]] ; then
		mv "${ROOT}"/etc/conf.d/clock "${ROOT}"/etc/conf.d/${clock}
	fi
	if [[ -e ${ROOT}/etc/init.d/clock ]] ; then
		rm -f "${ROOT}"/etc/init.d/clock
	fi
	if [[ -L ${ROOT}/etc/runlevels/boot/clock ]] ; then
		rm -f "${ROOT}"/etc/runlevels/boot/clock
		ln -snf /etc/init.d/${clock} "${ROOT}"/etc/runlevels/boot/${clock}
	fi
	if [[ -L ${ROOT}${LIBDIR}/rc/init.d/started/clock ]] ; then
		rm -f "${ROOT}${LIBDIR}"/rc/init.d/started/clock
		ln -snf /etc/init.d/${clock} "${ROOT}${LIBDIR}"/rc/init.d/started/${clock}
	fi

	# /etc/conf.d/rc is no longer used for configuration
	if [[ -e ${ROOT}/etc/conf.d/rc ]] ; then
		elog "/etc/conf.d/rc is no longer used for configuration."
		elog "Please migrate your settings to /etc/rc.conf as applicable"
		elog "and delete /etc/conf.d/rc"
	fi

	has_version sys-apps/baselayout && baselayout_migrate
}

baselayout_migrate() {
	# baselayout boot init scripts have been split out
	add_init boot $(cd "${D}"/usr/share/${PN}/runlevels/boot || exit; echo *)

	# Try to auto-add some addons when possible
	add_init_mit_config boot /etc/conf.d/cryptfs dmcrypt
	add_init_mit_config boot /etc/conf.d/dmcrypt dmcrypt
	add_init_mit_config boot /etc/mdadm.conf mdraid
	add_init_mit_config boot /etc/evms.conf evms
	[[ -e ${ROOT}/sbin/dmsetup ]] && add_init boot device-mapper
	[[ -e ${ROOT}/sbin/vgscan ]] && add_init boot lvm
	elog "Add on services (such as RAID/dmcrypt/LVM/etc...) are now stand alone"
	elog "init.d scripts.  If you use such a thing, make sure you have the"
	elog "required init.d scripts added to your boot runlevel."

	# Upgrade out state for baselayout-1 users
	if [[ ! -e ${ROOT}${LIBDIR}/rc/init.d/started ]] ; then
		(
		[[ -e ${ROOT}/etc/conf.d/rc ]] && source "${ROOT}"/etc/conf.d/rc
		svcdir=${svcdir:-/var/lib/init.d}
		if [[ ! -d ${ROOT}${svcdir}/started ]] ; then
			ewarn "No state found, and no state exists"
			elog "You should reboot this host"
		else
			mkdir -p "${ROOT}${LIBDIR}/rc/init.d"
			einfo "Moving state from ${ROOT}${svcdir} to ${ROOT}${LIBDIR}/rc/init.d"
			mv "${ROOT}${svcdir}"/* "${ROOT}${LIBDIR}"/rc/init.d
			rm -rf "${ROOT}${LIBDIR}"/rc/init.d/daemons \
				"${ROOT}${LIBDIR}"/rc/init.d/console
			umount "${ROOT}${svcdir}" 2>/dev/null
			rm -rf "${ROOT}${svcdir}"
		fi
		)
	fi

	# Handle the /etc/modules.autoload.d -> /etc/conf.d/modules transition
	if [[ -d ${ROOT}/etc/modules.autoload.d ]] ; then
		elog "Converting your /etc/modules.autoload.d/ files to /etc/conf.d/modules"
		rm -f "${ROOT}"/etc/modules.autoload.d/.keep*
		rmdir "${ROOT}"/etc/modules.autoload.d 2>/dev/null
		if [[ -d ${ROOT}/etc/modules.autoload.d ]] ; then
			local f v
			for f in "${ROOT}"/etc/modules.autoload.d/* ; do
				v=${f##*/}
				v=${v#kernel-}
				v=${v//[^[:alnum:]]/_}
				gawk -v v="${v}" -v f="${f##*/}" '
				BEGIN { print "\n### START: Auto-converted from " f "\n" }
				{
					if ($0 ~ /^[^#]/) {
						print "modules_" v "=\"${modules_" v "} " $1 "\""
						gsub(/[^[:alnum:]]/, "_", $1)
						printf "module_" $1 "_args_" v "=\""
						for (i = 2; i <= NF; ++i) {
							if (i > 2)
								printf " "
							printf $i
						}
						print "\"\n"
					} else
						print
				}
				END { print "\n### END: Auto-converted from " f "\n" }
				' "${f}" >> "${D}"/etc/conf.d/modules
			done
				rm -f "${f}"
			rmdir "${ROOT}"/etc/modules.autoload.d 2>/dev/null
		fi
	fi

	# Remove old baselayout links
	rm -f "${ROOT}"/etc/runlevels/boot/{check{fs,root},rmnologin}

}

pkg_postinst() {
	local runl
	install -d -m0755 ${ROOT}/etc/runlevels
	local runldir="${ROOT}usr/share/${PN}/runlevels"

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

	# SEE IF WE CAN UPGRADE /etc/inittab automatically
	# ================================================

	cat $FILESDIR/inittab-openrc.patch | ( cd $ROOT/etc; patch -p0 --dry-run > /dev/null 2>&1 )
	if [ $? -eq 0 ]
	then
		einfo "Patching $ROOTetc/inittab to work with new OpenRC..."
		cat $FILESDIR/inittab-openrc.patch | ( cd $ROOT/etc; patch -p0 > /dev/null 2>&1 )
		eend $?
	else
		einfo "Please ensure you run /etc/update to upgrade your /etc/inittab."
	fi

	# OTHER STUFF
	# ===========

	# update the dependency tree bug #224171
	[[ "${ROOT}" = "/" ]] && "${ROOT}/libexec"/rc/bin/rc-depend -u

	if [[ -d ${ROOT}/etc/modules.autoload.d ]] ; then
		ewarn "/etc/modules.autoload.d is no longer used.  Please convert"
		ewarn "your files to /etc/conf.d/modules and delete the directory."
	fi

	elog "You should now update all files in /etc, using etc-update"
	elog "or equivalent before rebooting."
	elog
	if [ -e $ROOTetc/conf.d/net ]
	then
		ewarn "IMPORTANT: your funtoo networking scripts will need to"
		ewarn "be upgraded."
		ewarn
		ewarn "Please read the Funtoo Networking Guide at"
		ewarn "http://www.funtoo.org/en/funtoo/networking/"
		ewarn
		ewarn "(This message triggered by existence of $ROOTetc/conf.d/net.)"
	fi
}
