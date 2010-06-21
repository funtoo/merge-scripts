# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/baselayout/baselayout-1.12.13.ebuild,v 1.1 2009/10/11 04:44:07 vapier Exp $

inherit flag-o-matic eutils toolchain-funcs multilib

DESCRIPTION="Filesystem baselayout and init scripts"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2
	http://dev.gentoo.org/~uberlord/baselayout/${P}.tar.bz2
	http://dev.gentoo.org/~azarah/baselayout/${P}.tar.bz2
	http://dev.gentoo.org/~vapier/dist/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="bootstrap build static unicode"

# This version of baselayout needs gawk in /bin, but as we do not have
# a c++ compiler during bootstrap, we cannot depend on it if "bootstrap"
# or "build" are in USE.
# We need to block old dhcpcd versions as they are no longer in system
# but may not be in users world file either. See bug #143885
RDEPEND="virtual/init
	!build? ( !bootstrap? (
		|| ( >=sys-apps/coreutils-6.10-r1 sys-apps/mktemp )
		>=sys-libs/readline-5.0-r1
		>=app-shells/bash-3.1_p7
		>=sys-apps/coreutils-5.2.1
		>=sys-apps/findutils-4.2.18
	) )
	!<net-misc/dhcpcd-2.0.0"
DEPEND="virtual/os-headers
	>=sys-apps/portage-2.0.51"
PDEPEND="!build? ( !bootstrap? ( >=sys-apps/module-init-tools-3.2.2-r3 ) )"

src_unpack() {
	unpack ${A}
	cd "${S}"

	# Setup unicode defaults for silly unicode users
	if use unicode ; then
		sed -i -e '/^UNICODE=/s:no:yes:' etc/rc.conf
	fi

	# Tweak arch-specific details
	cd "${S}"

	case $(tc-arch) in
	sparc)
		# Disable interactive boot on sparc due to stty calls, #104067
		sed -i -e '/^RC_INTERACTIVE=/s:yes:no:' etc/conf.d/rc || die
		;;
	esac

	# Use correct path to filefuncs.so on multilib systems
	sed -i -e "s:/lib/rcscripts:/$(get_libdir)/rcscripts:" \
		src/awk/cachedepends.awk sbin/functions.sh || die
}

src_compile() {
	local libdir="lib"

	use static && append-ldflags -static

	[[ ${SYMLINK_LIB} == "yes" ]] && libdir=$(get_abi_LIBDIR "${DEFAULT_ABI}")

	make -C "${S}"/src \
		CC="$(tc-getCC)" \
		LD="$(tc-getCC) ${LDFLAGS}" \
		CFLAGS="${CFLAGS}" \
		LIBDIR="${libdir}" || die
}

# ${PATH} should include where to get MAKEDEV when calling this
# function
create_dev_nodes() {
	case $(tc-arch) in
		# amd64 must use generic-i386 because amd64/x86_64 does not have
		# a generic option at this time, and the default 'generic' ends
		# up erroring out, because MAKEDEV internally doesn't know what
		# to use
		arm*)    suffix=-arm ;;
		alpha)   suffix=-alpha ;;
		amd64)   suffix=-i386 ;;
		hppa)    suffix=-hppa ;;
		ia64)    suffix=-ia64 ;;
		m68k)    suffix=-m68k ;;
		mips*)   suffix=-mips ;;
		ppc*)    suffix=-powerpc ;;
		s390*)   suffix=-s390 ;;
		sh*)     suffix=-sh ;;
		sparc*)  suffix=-sparc ;;
		x86)     suffix=-i386 ;;
	esac

	einfo "Using generic${suffix} to make $(tc-arch) device nodes..."
	MAKEDEV generic${suffix}
	MAKEDEV sg scd rtc hde hdf hdg hdh input audio video
}

# This is a temporary workaround until bug 9849 is completely solved
# in portage.  We need to create the directories so they're available
# during src_install, but when src_install is finished, call unkdir
# to remove any empty directories instead of leaving them around.
kdir() {
	typeset -a args
	typeset d

	# Create the directories for the remainder of src_install, and
	# remember how to create the directories later.
	for d in "$@"; do
		if [[ $d == /* ]]; then
			install -d "${args[@]}" "${D}/${d}"
			cat >> "${D}/usr/share/baselayout/mkdirs.sh" <<EOF
if [ ! -d "\${ROOT}/${d}" ] ; then \\
	install -d ${args[@]} "\${ROOT}/${d}" 2>/dev/null \\
		|| ewarn "  can't create ${d}"
	touch "\${ROOT}/${d}/.keep" 2>/dev/null \\
		|| ewarn "  can't create ${d}/.keep"
fi
EOF
		else
			args=("${args[@]}" "${d}")
		fi
	done
}

# Continued from kdir above...  This function removes any empty
# directories as a temporary workaround for bug 9849.  The directories
# (and .keep files) are re-created in pkg_postinst, which means they
# aren't listed in CONTENTS, unfortunately.
unkdir() {
	einfo "Running unkdir to workaround bug 9849"
	find "${D}" -depth -type d -exec rmdir {} \; 2>/dev/null
	if [[ $? == 127 ]]; then
		ewarn "Problem running unkdir: find command not found"
	fi
}

# Same as kdir above, but for symlinks #103618
ksym() {
	echo "[[ ! -e ${ROOT}/$2 ]] && { ln -s '$1' '${ROOT}/$2' &> /dev/null || ewarn '  unable to symlink $2 to $1' ; }" \
		>> "${D}"/usr/share/baselayout/mklinks.sh
}

src_install() {
	local dir libdirs libdirs_env rcscripts_dir

	# This directory is to stash away things that will be used in
	# pkg_postinst; it's needed first for kdir to function
	dodir /usr/share/baselayout

	# Jeremy Huddleston <eradicator@gentoo.org>
	# For multilib, we want to make sure that all our multilibdirs exist
	# and make lib even if it's not listed as one (like on amd64/ppc64
	# which sometimes has lib32/lib64 instead of lib/lib64).
	# lib should NOT be a symlink to one of the other libdirs.
	# Old systems with symlinks won't be affected by this change, as the
	# symlinks already exist and won't get removed, but new systems will
	# be setup properly.
	#
	# I'll be making a script to convert existing systems from symlink to
	# nosymlink and putting it in /usr/portage/scripts.
	libdirs=$(get_all_libdirs)
	: ${libdirs:=lib}	# it isn't that we don't trust multilib.eclass...

	# This should be /lib/rcscripts, but we have to support old profiles too.
	if [[ ${SYMLINK_LIB} == "yes" ]]; then
		rcscripts_dir="/$(get_abi_LIBDIR ${DEFAULT_ABI})/rcscripts"
	else
		rcscripts_dir="/lib/rcscripts"
	fi

	einfo "Creating directories..."
	kdir /usr
	kdir /usr/local
	kdir /boot
	kdir /dev
	kdir /dev/pts
	kdir /dev/shm
	kdir /etc/conf.d
	kdir /etc/cron.daily
	kdir /etc/cron.hourly
	kdir /etc/cron.monthly
	kdir /etc/cron.weekly
	kdir /etc/env.d
	dodir /etc/init.d			# .keep file might mess up init.d stuff
	kdir /etc/modules.autoload.d
	kdir /etc/modprobe.d
	kdir /etc/opt
	kdir /home
	kdir ${rcscripts_dir}
	kdir ${rcscripts_dir}/awk
	kdir ${rcscripts_dir}/sh
	kdir ${rcscripts_dir}/net
	# Only install /mnt stuff at bootstrap time #88835 / #90022
	if use build ; then
		kdir /mnt
		kdir -m 0700 /mnt/cdrom
		kdir -m 0700 /mnt/floppy
	fi
	kdir /opt
	kdir -o root -g uucp -m0775 /var/lock
	kdir /proc
	kdir -m 0700 /root
	kdir /sbin
	kdir /sys	# for 2.6 kernels
	kdir /usr/bin
	kdir /usr/include
	kdir /usr/include/asm
	kdir /usr/include/linux
	kdir /usr/local/bin
	kdir /usr/local/games
	kdir /usr/local/sbin
	kdir /usr/local/share
	kdir /usr/local/share/doc
	kdir /usr/local/share/man
	kdir /usr/local/src
	kdir ${PORTDIR}
	kdir /usr/sbin
	kdir /usr/share/doc
	kdir /usr/share/info
	kdir /usr/share/man
	kdir /usr/share/misc
	kdir /usr/src
	kdir -m 1777 /tmp
	kdir /var
	dodir /var/db/pkg			# .keep file messes up Portage
	kdir /var/lib/misc
	kdir /var/lock/subsys
	kdir /var/log/news
	kdir /var/run
	kdir /var/spool
	kdir /var/state
	kdir -m 1777 /var/tmp

	for dir in ${libdirs}; do
		libdirs_env=${libdirs_env:+$libdirs_env:}/${dir}:/usr/${dir}:/usr/local/${dir}
		[[ ${dir} == "lib" && ${SYMLINK_LIB} == "yes" ]] && continue
		kdir /${dir}
		kdir /usr/${dir}
		kdir /usr/local/${dir}
	done

	# Ugly compatibility with stupid ebuilds and old profiles symlinks
	if [[ ${SYMLINK_LIB} == "yes" ]] ; then
		rm -r "${D}"/{lib,usr/lib,usr/local/lib} &> /dev/null
		ksym $(get_abi_LIBDIR ${DEFAULT_ABI}) /lib
		ksym $(get_abi_LIBDIR ${DEFAULT_ABI}) /usr/lib
		ksym $(get_abi_LIBDIR ${DEFAULT_ABI}) /usr/local/lib
	fi

	# FHS compatibility symlinks stuff
	ksym /var/tmp /usr/tmp
	ksym share/man /usr/local/man

	#
	# Setup files in /etc
	#
	insopts -m0644
	insinto /etc
	doins -r "${S}"/etc/* || die
	fperms 0640 /etc/sysctl.conf

	# Install some files to /usr/share/baselayout instead of /etc to keep from
	# (1) overwriting the user's settings, (2) screwing things up when
	# attempting to merge files, (3) accidentally packaging up personal files
	# with quickpkg
	fperms 0600 /etc/shadow
	mv "${D}"/etc/{passwd,shadow,group,fstab,hosts,issue.devfix} "${D}"/usr/share/baselayout || die

	# doinitd doesnt respect symlinks
	dodir /etc/init.d
	cp -P "${S}"/init.d/* "${D}"/etc/init.d/ || die "doinitd"
	#doinitd "${S}"/init.d/* || die "doinitd"
	doconfd "${S}"/etc/conf.d/* || die "doconfd"
	doenvd "${S}"/etc/env.d/* || die "doenvd"
	insinto /etc/modules.autoload.d
	doins "${S}"/etc/modules.autoload.d/* || die
	insinto /etc/modprobe.d
	doins "${S}"/etc/modprobe.d/* || die

	# Special-case uglyness... For people updating from lib32 -> lib amd64
	# profiles, keep lib32 in the search path while it's around
	if has_multilib_profile && [ -d /lib32 -o -d /usr/lib32 ] && ! hasq lib32 ${libdirs}; then
		libdirs_env="${libdirs_env}:/lib32:/usr/lib32:/usr/local/lib32"
	fi

	# List all the multilib libdirs in /etc/env/04multilib (only if they're
	# actually different from the normal
	if has_multilib_profile || [[ $(get_libdir) != "lib" || -n ${CONF_MULTILIBDIR} ]]; then
		echo "LDPATH=\"${libdirs_env}\"" > 04multilib
		doenvd 04multilib
	fi

	# As of baselayout-1.10-1-r1, sysvinit is its own package again, and
	# provides the inittab itself
	rm -f "${D}"/etc/inittab

	# Stash the rc-lists for use during pkg_postinst
	cp -r "${S}"/rc-lists "${D}"/usr/share/baselayout

	# rc-scripts version for testing of features that *should* be present
	echo "Gentoo Base System release ${PV}" > "${D}"/etc/gentoo-release

	#
	# Setup files related to /dev
	#
	into /
	dosbin "${S}"/sbin/MAKEDEV
	dosym ../../sbin/MAKEDEV /usr/sbin/MAKEDEV
	dosym ../sbin/MAKEDEV /dev/MAKEDEV

	#
	# Setup files in /bin
	#
	cd "${S}"/bin
	dobin rc-status checkpath || die

	#
	# Setup files in /sbin
	#
	cd "${S}"/sbin
	into /
	dosbin rc rc-update || die
	dosym rc-update /sbin/update-rc
	# These moved from /etc/init.d/ to /sbin to help newb systems
	# from breaking
	dosbin runscript.sh functions.sh || die

	# Compat symlinks between /etc/init.d and /sbin
	# (some stuff have hardcoded paths)
	dosym ../../sbin/depscan.sh /etc/init.d/depscan.sh
	dosym ../../sbin/runscript.sh /etc/init.d/runscript.sh
	dosym ../../sbin/functions.sh /etc/init.d/functions.sh

	#
	# Setup files in /lib/rcscripts
	# These are support files for other things in baselayout that needn't be
	# under CONFIG_PROTECTed /etc
	#
	cd "${S}"/sbin
	exeinto ${rcscripts_dir}/sh
	doexe rc-services.sh rc-daemon.sh rc-help.sh || die

	# This is for new depscan.sh written in awk
	cd "${S}"/sbin
	into /
	dosbin depscan.sh
	insinto ${rcscripts_dir}/awk
	doins "${S}"/src/awk/*.awk

	# Original design had these in /etc/net.modules.d but that is too
	# problematic with CONFIG_PROTECT
	dodir ${rcscripts_dir}
	cp -pPR "${S}"/lib/rcscripts/net "${D}"${rcscripts_dir}
	chown -R root:0 "${D}"${rcscripts_dir}

	#
	# Install baselayout documentation
	#
	doman "${S}"/man/*.*
	docinto /
	dodoc "${S}"/ChangeLog{,.svn}

	#
	# Install baselayout utilities
	#
	local libdir="lib"
	[[ ${SYMLINK_LIB} == "yes" ]] && libdir=$(get_abi_LIBDIR "${DEFAULT_ABI}")

	cd "${S}"/src
	emake DESTDIR="${D}" LIBDIR="${libdir}" install || die

	# Hack to fix bug 9849, continued in pkg_postinst
	unkdir
}

# Support function for remapping old wireless dns vars
remap_dns_vars() {
	local f="$1"

	if [[ -f ${ROOT}/etc/conf.d/${f} ]]; then
		sed -e 's/\<domain_/dns_domain_/g' \
			-e 's/\<mac_domain_/mac_dns_domain_/g' \
			-e 's/\<nameservers_/dns_servers_/g' \
			-e 's/\<mac_nameservers_/mac_dns_servers_/g' \
			-e 's/\<searchdomains_/dns_search_domains_/g' \
			-e 's/\<mac_searchdomains_/mac_dns_search_domains_/g' \
			"${ROOT}"/etc/conf.d/${f} > "${D}"/etc/conf.d/${f}
	fi
}

pkg_preinst() {
	# When downgrading from 1.13 we need to erase net.lo as it's a symlink
	# and it's about to become a file - this is fatal in /etc
	[[ -L "${ROOT}"etc/init.d/net.lo ]] && rm -f "${ROOT}"etc/init.d/net.lo

	# Reincarnate dirs from kdir/unkdir (hack for bug 9849)
	# This needs to be in pkg_preinst() rather than pkg_postinst() as
	# portage may create some dirs/files that'll screw us up (like /usr/lib/debug)
	einfo "Creating directories and .keep files."
	einfo "Some of these might fail if they're read-only mounted"
	einfo "filesystems, for example /dev or /proc.  That's okay!"
	source "${D}"/usr/share/baselayout/mkdirs.sh
	source "${D}"/usr/share/baselayout/mklinks.sh
	echo

	if [[ -f ${ROOT}/etc/modules.autoload && ! -d ${ROOT}/etc/modules.autoload.d ]]; then
		mkdir -p "${ROOT}"/etc/modules.autoload.d
		mv -f "${ROOT}"/etc/modules.autoload \
			"${ROOT}"/etc/modules.autoload.d/kernel-2.4
		ln -snf modules.autoload.d/kernel-2.4 "${ROOT}"/etc/modules.autoload
	fi

	# Change some vars introduced in baselayout-1.11.0 before we go stable
	# The new names make more sense and allow nis_domain
	# for use in baselayout-1.12.0
	remap_dns_vars net
	remap_dns_vars wireless
}

pkg_postinst() {
	local x y

	# Create /boot/boot symlink in pkg_postinst because sometimes
	# /boot is a FAT filesystem.  When that is the case, then the
	# symlink will fail.  Consequently, if we create it in
	# src_install, then merge will fail.  AFAIK there is no point to
	# this symlink except for misconfigured grubs.  See bug 50108
	# (05 May 2004 agriffis)
	ln -sn . "${ROOT}"/boot/boot 2>/dev/null

	# For the bootstrap scenario with an empty /dev, let's fill the
	# sucker with generic crude ... some day we should think about
	# slimming this way down as we've moved on to udev/devfs
	if use build ; then
		if [[ ! -e ${ROOT}/dev/.devfsd && ! -e ${ROOT}/dev/.udev ]] ; then
			echo
			einfo "Making device node tarball (this could take a couple minutes)"
			cd "${ROOT}"/dev || die
			PATH=${ROOT}/sbin:${PATH} create_dev_nodes
		fi
	fi

	# Set up default runlevel symlinks
	# This used to be done in src_install but required knowledge of ${ROOT},
	# which meant that it was effectively broken for binary installs.
	if [[ -z $(/bin/ls "${ROOT}"/etc/runlevels 2>/dev/null) ]]; then
		for x in boot default nonetwork single; do
			einfo "Creating default runlevel symlinks for ${x}"
			mkdir -p "${ROOT}"/etc/runlevels/${x}
			for y in $(<"${ROOT}"/usr/share/baselayout/rc-lists/${x}); do
				if [[ ! -e ${ROOT}/etc/init.d/${y} ]]; then
					ewarn "init.d/${y} not found -- ignoring"
				else
					ln -sfn /etc/init.d/${y} \
						"${ROOT}"/etc/runlevels/${x}/${y}
				fi
			done
		done
	fi

	# Create /etc/hosts in pkg_postinst so we don't overwrite an
	# existing file during bootstrap
	if [[ ! -e ${ROOT}/etc/hosts ]]; then
		cp "${ROOT}"/usr/share/baselayout/hosts "${ROOT}"/etc
	fi

	# Touching /etc/passwd and /etc/shadow after install can be fatal, as many
	# new users do not update them properly...  see src_install() for why they
	# are in /usr/share/baselayout/
	for x in passwd shadow group fstab ; do
		if [[ -e ${ROOT}/etc/${x} ]] ; then
			touch "${ROOT}/etc/${x}"
		else
			cp "${ROOT}/usr/share/baselayout/${x}" "${ROOT}/etc/${x}"
		fi
	done

	# Under what circumstances would mtab be a symlink?  It would be
	# nice if there were an explanatory comment here
	if [[ -L ${ROOT}/etc/mtab ]]; then
		rm -f "${ROOT}/etc/mtab"
		if [[ ${ROOT} == / ]]; then
			cp /proc/mounts "${ROOT}/etc/mtab"
		else
			touch "${ROOT}/etc/mtab"
		fi
	fi

	# We should only install empty files if these files don't already exist.
	[[ -e ${ROOT}/var/log/lastlog ]] || \
		touch "${ROOT}/var/log/lastlog"
	[[ -e ${ROOT}/var/run/utmp ]] || \
		install -m 0664 -g utmp /dev/null "${ROOT}/var/run/utmp"
	[[ -e ${ROOT}/var/log/wtmp ]] || \
		install -m 0664 -g utmp /dev/null "${ROOT}/var/log/wtmp"

	# Reload init to fix unmounting problems of / on next reboot.
	# This is really needed, as without the new version of init cause init
	# not to quit properly on reboot, and causes a fsck of / on next reboot.
	if [[ ${ROOT} == / ]] && ! use build && ! use bootstrap; then
		# Regenerate init.d dependency tree
		/sbin/depscan.sh --update &>/dev/null
	else
		rm -f "${ROOT}"/etc/modules.conf
	fi

	# This is also written in src_install (so it's in CONTENTS), but
	# write it here so that the new version is immediately in the file
	# (without waiting for the user to do etc-update)
	rm -f "${ROOT}"/etc/._cfg????_gentoo-release
	echo "Gentoo Base System release ${PV}" > "${ROOT}"/etc/gentoo-release

	echo
	einfo "Please be sure to update all pending '._cfg*' files in /etc,"
	einfo "else things might break at your next reboot!  You can use 'etc-update'"
	einfo "to accomplish this:"
	einfo
	einfo "  # etc-update"
	echo

	for f in "${ROOT}"etc/init.d/net.* ; do
		[[ -L ${f} || ${f} == "${ROOT}etc/init.d/net.lo" ]] && continue
		echo
		einfo "WARNING: You have older net.* files in ${ROOT}etc/init.d/"
		einfo "They need to be converted to symlinks to net.lo.  If you haven't"
		einfo "made personal changes to those files, you can update with the"
		einfo "following command:"
		einfo
		einfo " /bin/ls '${ROOT}'etc/init.d/net.* | grep -v '/net.lo$' | xargs -n1 ln -sfvn net.lo"
		echo
		break
	done

	if sed -e 's/#.*//' "${ROOT}"/etc/conf.d/{net,wireless} 2>/dev/null \
		| egrep -q '\<(domain|nameservers|searchdomains)_' ; then
			echo
			ewarn "You have deprecated variables in ${ROOT}/etc/conf.d/net"
			ewarn "or ${ROOT}/etc/conf.d/wireless"
			ewarn
			ewarn "domain_* -> dns_domain_*"
			ewarn "nameservers_* -> dns_servers_*"
			ewarn "searchdomains_* -> dns_search_domains_*"
			ewarn
			ewarn "They have been converted for you - ensure that you"
			ewarn "update them via 'etc-update'"
			echo
	fi

	if sed -e 's/#.*//' "${ROOT}"/etc/conf.d/net 2>/dev/null \
		| egrep -q '\<(iface_|gateway=|ifconfig_|aliases_|broadcasts_|netmasks_|inet6_|ipaddr_|iproute_)'; then
			echo
			ewarn "You are using deprecated variables in ${ROOT}/etc/conf.d/net"
			ewarn
			ewarn "You are advised to review the new configuration variables as"
			ewarn "found in '${ROOT}'/etc/conf.d/net.example as there is no"
			ewarn "guarantee that they will work in future versions."
			echo
	fi

	# Remove old stuff that may cause problems.
	if [[ -e "${ROOT}"/etc/env.d/01hostname ]] ; then
		rm -f "${ROOT}"/etc/env.d/01hostname
	fi
	if [[ -e "${ROOT}"/etc/init.d/domainname ]] ; then
		rm -f "${ROOT}"/etc/init.d/domainname
		rm -f "${ROOT}"/etc/runlevels/*/domainname
		ewarn "The domainname init script has been removed in this version."
		ewarn "Consult '${ROOT}'/etc/conf.d/net.example for details about how"
		ewarn "to apply dns/nis information to the loopback interface."
	fi

	elog "The default setting for wiping /tmp has been set to 'yes'."
	elog "Consult /etc/conf.d/bootmisc for more information."
}

pkg_prerm() {
	# Older baselayout installed a net.eth0 link by default
	# which means during an upgrade, that link gets lost
	if has_version '=sys-apps/baselayout-2*' && [[ -L ${ROOT}/etc/init.d/net.eth0 ]] ; then
		readlink "${ROOT}"/etc/init.d/net.eth0 > "${T}"/carry-the-0
	else
		rm -f "${T}"/carry-the-0
	fi
}

pkg_postrm() {
	# Older baselayout installed a net.eth0 link by default
	# which means during an upgrade, that link gets lost
	if has_version '=sys-apps/baselayout-2*' &&
	   [[ ! -e ${ROOT}/etc/init.d/net.eth0 ]] &&
	   [[ -e ${T}/carry-the-0 ]]
	then
		ln -s $(<"${T}"/carry-the-0) "${ROOT}"/etc/init.d/net.eth0
	fi
}
