# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/openrc/openrc-0.8.2-r1.ebuild,v 1.6 2011/05/13 19:06:47 armin76 Exp $

EAPI="2"

inherit eutils flag-o-matic multilib toolchain-funcs

GITHUB_REPO="${PN}"
GITHUB_USER="funtoo"
GITHUB_TAG="funtoo-openrc-${PVR}"

NETV="1.0.8"
GITHUB_REPO_CN="corenetwork"
GITHUB_TAG_CN="$NETV"

SRC_URI="
	https://www.github.com/${GITHUB_USER}/${GITHUB_REPO}/tarball/${GITHUB_TAG} -> ${PN}-${GITHUB_TAG}.tar.gz
	https://www.github.com/${GITHUB_USER}/${GITHUB_REPO_CN}/tarball/${GITHUB_TAG_CN} -> corenetwork-${GITHUB_TAG_CN}.tar.gz"

DESCRIPTION="OpenRC manages the services, startup and shutdown of a host"
HOMEPAGE="http://www.gentoo.org/proj/en/base/openrc/"

PROVIDE="virtual/baselayout"
RESTRICT="nomirror"

LICENSE="BSD-2"
SLOT="0"
IUSE="debug elibc_glibc ncurses pam selinux unicode kernel_linux kernel_FreeBSD"

RDEPEND="virtual/init
	kernel_FreeBSD? ( sys-process/fuser-bsd )
	elibc_glibc? ( >=sys-libs/glibc-2.5 )
	ncurses? ( sys-libs/ncurses )
	pam? ( virtual/pam )
	>=sys-apps/baselayout-2.0.0
	kernel_linux? ( !<sys-apps/module-init-tools-3.2.2-r2 )
	!<sys-fs/udev-133
	!<sys-apps/sysvinit-2.86-r11"
DEPEND="${RDEPEND}
	virtual/os-headers"

make_args() {
	unset LIBDIR #266688

	MAKE_ARGS="${MAKE_ARGS} LIBNAME=$(get_libdir) LIBEXECDIR=/$(get_libdir)/rc"
	MAKE_ARGS="${MAKE_ARGS} MKOLDNET=yes"

	local brand="Unknown"
	if use kernel_linux ; then
		MAKE_ARGS="${MAKE_ARGS} OS=Linux"
		brand="Linux"
	elif use kernel_FreeBSD ; then
		MAKE_ARGS="${MAKE_ARGS} OS=FreeBSD"
		brand="FreeBSD"
	fi
	if use selinux; then
			MAKE_ARGS="${MAKE_ARGS} MKSELINUX=yes"
	fi
	export BRANDING="Gentoo ${brand}"
}

pkg_setup() {
	export DEBUG=$(usev debug)
	export MKPAM=$(usev pam)
	export MKTERMCAP=$(usev ncurses)
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	sed -i 's:0444:0644:' mk/sys.mk
	sed -i "/^DIR/s:/openrc:/${PF}:" doc/Makefile #241342
}

src_prepare() {
	# rename github directories to the names we're expecting:
	local old=${WORKDIR}/${GITHUB_USER}-${PN}-*
	mv $old "${WORKDIR}/${P}" || die "move fail 1"
	old="${WORKDIR}/${GITHUB_USER}-corenetwork-*"
	mv $old "${WORKDIR}/corenetwork-${NETV}" || die "move fail 2"
}


src_compile() {
	make_args
	tc-export CC AR RANLIB
	emake ${MAKE_ARGS} || die "emake ${MAKE_ARGS} failed"
}

# set_config <file> <option name> <yes value> <no value> test
# a value of "#" will just comment out the option
set_config() {
	local file="${D}/$1" var=$2 val com
	eval "${@:5}" && val=$3 || val=$4
	[[ ${val} == "#" ]] && com="#" && val='\2'
	sed -i -r -e "/^#?${var}=/{s:=([\"'])?([^ ]*)\1?:=\1${val}\1:;s:^#?:${com}:}" "${file}"
}
set_config_yes_no() {
	set_config "$1" "$2" YES NO "${@:3}"
}

corenet_install() {
	# Remove upstream networking parts:

	for pat in ${D}/etc/init.d/{network,staticroute} \
	${D}/usr/share/openrc/runlevels/boot/{network,staticroute} \
	${D}/etc/conf.d/{network,staticroute}; do
		rm -f "$pat" || die "Couldn't remove upstream $pat from source."
	done

	# Install funtoo networking parts:

	cd ${WORKDIR}/corenetwork-${NETV} || die
	dodoc docs/index.rst || die
	exeinto /etc/init.d || die
	doexe init.d/{netif.tmpl,netif.lo} || die
	cp -a netif.d ${D}/etc || die
	chown -R root:root ${D}/etc/netif.d || die
	chmod -R 0644 ${D}/etc/netif.d || die
	ln -s /etc/init.d/netif.lo ${D}/usr/share/openrc/runlevels/sysinit/netif.lo || die
}

src_install() {
	make_args
	emake ${MAKE_ARGS} DESTDIR="${D}" install || die

	# install the readme for the new network scripts
	dodoc README.newnet

	# move the shared libs back to /usr so ldscript can install
	# more of a minimal set of files
	# disabled for now due to #270646
	#mv "${D}"/$(get_libdir)/lib{einfo,rc}* "${D}"/usr/$(get_libdir)/ || die
	#gen_usr_ldscript -a einfo rc
	gen_usr_ldscript libeinfo.so
	gen_usr_ldscript librc.so

	keepdir /$(get_libdir)/rc/{init.d,tmp}

	# Backup our default runlevels
	dodir /usr/share/"${PN}"
	cp -PR "${D}"/etc/runlevels "${D}"/usr/share/${PN} || die
	rm -rf "${D}"/etc/runlevels

	# Stick with "old" net as the default for now
	doconfd conf.d/net || die
	pushd "${D}"/usr/share/${PN}/runlevels/boot > /dev/null
	rm -f network staticroute
	ln -s /etc/init.d/net.lo net.lo
	popd > /dev/null

	# Setup unicode defaults for silly unicode users
	set_config_yes_no /etc/rc.conf unicode use unicode

	# Cater to the norm
	set_config_yes_no /etc/conf.d/keymaps windowkeys '(' use x86 '||' use amd64 ')'

	# On HPPA, do not run consolefont by default (bug #222889)
	if use hppa; then
		rm -f "${D}"/usr/share/openrc/runlevels/boot/consolefont
	fi

	# Support for logfile rotation
	insinto /etc/logrotate.d
	newins "${FILESDIR}"/openrc.logrotate openrc

	corenet_install
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
pkg_preinst() {
	local f LIBDIR=$(get_libdir)

	# avoid default thrashing in conf.d files when possible #295406
	if [[ -e ${ROOT}/etc/conf.d/hostname ]] ; then
		(
		unset hostname HOSTNAME
		source "${ROOT}"/etc/conf.d/hostname
		: ${hostname:=${HOSTNAME}}
		[[ -n ${hostname} ]] && set_config /etc/conf.d/hostname hostname "${hostname}"
		)
	fi

	# upgrade timezone file ... do it before moving clock
	if [[ -e ${ROOT}/etc/conf.d/clock && ! -e ${ROOT}/etc/timezone ]] ; then
		(
		unset TIMEZONE
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

	# set default interactive shell to sulogin if it exists
	set_config /etc/rc.conf rc_shell /sbin/sulogin "#" test -e /sbin/sulogin
}

pkg_postinst() {

	#funtoo

	local runl
	install -d -m0755 ${ROOT}/etc/runlevels
	local runldir="${ROOT}usr/share/openrc/runlevels"

	# Remove old baselayout links
	rm -f "${ROOT}"/etc/runlevels/boot/{check{fs,root},rmnologin}
	rm -f "${ROOT}"/etc/init.d/{depscan,runscript}.sh
	rm -f "${ROOT}"/etc/runlevels/boot/netif.lo

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
		[ ! -d ${runldir}/${runl} ] && continue
		for init in $( cd "$runldir/$runl"; echo * )
		do
			if [ -e ${ROOT}/etc/runlevels/${runl}/${init} ] && [ ! -e ${runldir}/${runl}/${init} ]
			then
				ewarn "Initscript ${init} exists in runlevel ${runl} but not in OpenRC."
			fi
		done
	done

	# OTHER STUFF
	# ===========

	# update the dependency tree bug #224171
	[[ "${ROOT}" = "/" ]] && "${ROOT}/libexec"/rc/bin/rc-depend -u

	elog "You should now update all files in /etc, using etc-update"
	elog "or equivalent before restarting any services or this host."
	elog

	if path_exists -o "${ROOT}"/etc/conf.d/local.{start,stop} ; then
		ewarn "/etc/conf.d/local.{start,stop} are deprecated.  Please convert"
		ewarn "your files to /etc/conf.d/local and delete the files."
	fi
}
