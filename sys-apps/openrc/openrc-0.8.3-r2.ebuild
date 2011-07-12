# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/openrc/openrc-0.3.0-r1.ebuild,v 1.1 2008/10/08 16:19:11 cardoe Exp $

EAPI="2"

inherit eutils flag-o-matic multilib toolchain-funcs

DESCRIPTION="OpenRC manages the services, startup and shutdown of a host"
HOMEPAGE="http://roy.marples.name/openrc"
PROVIDE="virtual/baselayout"
RESTRICT="nomirror"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~x86 ~amd64 ~sparc"
IUSE="debug ncurses pam unicode kernel_linux kernel_FreeBSD"

RDEPEND="kernel_linux? ( >=sys-apps/sysvinit-2.86-r11 )
	kernel_FreeBSD? ( virtual/init sys-process/fuser-bsd )
	ncurses? ( sys-libs/ncurses )
	pam? ( virtual/pam )
	>=sys-apps/baselayout-2.1
	>=sys-fs/udev-135
	sys-apps/iproute2"

DEPEND="ncurses? ( sys-libs/ncurses ) pam? ( virtual/pam ) virtual/os-headers"

GITHUB_REPO="${PN}"
GITHUB_USER="funtoo"
GITHUB_TAG="funtoo-openrc-0.8.3"

NETV="1.1-r1"
GITHUB_REPO_CN="corenetwork"
GITHUB_TAG_CN="$NETV"

SRC_URI="
	https://www.github.com/${GITHUB_USER}/${GITHUB_REPO}/tarball/${GITHUB_TAG} -> ${PN}-${GITHUB_TAG}.tar.gz
	https://www.github.com/${GITHUB_USER}/${GITHUB_REPO_CN}/tarball/${GITHUB_TAG_CN} -> corenetwork-${GITHUB_TAG_CN}.tar.gz"

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

pre_src_prepare() {
	# rename github directories to the names we're expecting:
	local old=${WORKDIR}/${GITHUB_USER}-${PN}-*
	mv $old "${WORKDIR}/${P}" || die "move fail 1"
	old="${WORKDIR}/${GITHUB_USER}-corenetwork-*"
	mv $old "${WORKDIR}/corenetwork-${NETV}" || die "move fail 2"
}

src_compile() {
	cd $S
	# catch people running `ebuild` w/out setup
	if [[ -z ${MAKE_ARGS} ]] ; then
		die "Your MAKE_ARGS is empty ... are you running 'ebuild' but forgot to execute 'setup' ?"
	fi

	#sed -i "/^VERSION[[:space:]]*=/s:=.*:=${PV}:" Makefile

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

	# Remove upstream networking parts:

	for pat in ${D}/etc/init.d/{net.lo,network,staticroute} \
	${D}/usr/share/openrc/runlevels/boot/{net.lo,network,staticroute} \
	${D}/etc/conf.d/{net,network,staticroute}; do
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
	local runldir="${ROOT}usr/share/openrc/runlevels"

	# Remove old baselayout links
	rm -f "${ROOT}"/etc/runlevels/boot/{check{fs,root},rmnologin}
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
				echo "Initscript ${init} exists in runlevel ${runl} but not in OpenRC."
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

	if path_exists -o "${ROOT}"/etc/conf.d/local.{start,stop} ; then
		ewarn "/etc/conf.d/local.{start,stop} are deprecated.  Please convert"
		ewarn "your files to /etc/conf.d/local and delete the files."
	fi
}
