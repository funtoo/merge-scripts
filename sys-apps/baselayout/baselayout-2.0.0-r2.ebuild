# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/baselayout/baselayout-2.0.0.ebuild,v 1.7 2008/08/19 17:51:19 zmedico Exp $

inherit multilib

DESCRIPTION="Filesystem baselayout and init scripts"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2
	http://dev.gentoo.org/~vapier/dist/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc sparc-fbsd x86 x86-fbsd"
IUSE="build"

PDEPEND="sys-apps/openrc"

pkg_preinst() {
	if [ "$ROOT" != "/" ]
	then
		# This should be /lib/rcscripts, but we have to support old profiles too.
		if [[ ${SYMLINK_LIB} == "yes" ]]; then
			rcscripts_dir="${ROOT}$(get_abi_LIBDIR ${DEFAULT_ABI})/rcscripts"
		else
			rcscripts_dir="${ROOT}lib/rcscripts"
		fi
		einfo "Creating directories..."
		install -d ${ROOT}usr
		install -d ${ROOT}usr/local
		install -d ${ROOT}boot
		install -d ${ROOT}dev
		install -d ${ROOT}dev/pts
		install -d ${ROOT}dev/shm
		install -d ${ROOT}etc/conf.d
		install -d ${ROOT}etc/cron.daily
		install -d ${ROOT}etc/cron.hourly
		install -d ${ROOT}etc/cron.monthly
		install -d ${ROOT}etc/cron.weekly
		install -d ${ROOT}etc/env.d
		install -d ${ROOT}etc/modules.autoload.d
		install -d ${ROOT}etc/modules.d
		install -d ${ROOT}etc/opt
		install -d ${ROOT}etc/profile.d
		install -d ${ROOT}home
		install -d ${rcscripts_dir}
		install -d ${ROOT}mnt
		install -d ${ROOT}mnt/cdrom
		install -d ${ROOT}mnt/floppy
		install -d ${ROOT}opt
		install -d -o root -g uucp -m0775 ${ROOT}var/lock
		install -d ${ROOT}proc
		install -d -m 0700 ${ROOT}root
		install -d ${ROOT}sbin
		install -d ${ROOT}sys	# for 2.6 kernels
		install -d ${ROOT}usr/bin
		install -d ${ROOT}usr/include
		install -d ${ROOT}usr/include/asm
		install -d ${ROOT}usr/include/linux
		install -d ${ROOT}usr/local/bin
		install -d ${ROOT}usr/local/games
		install -d ${ROOT}usr/local/sbin
		install -d ${ROOT}usr/local/share
		install -d ${ROOT}usr/local/share/doc
		install -d ${ROOT}usr/local/share/man
		ln -snf share/man ${ROOT}/usr/local/man
		install -d ${ROOT}usr/local/src
		install -d ${ROOT}usr/portage
		install -d ${ROOT}usr/sbin
		install -d ${ROOT}usr/share/doc
		install -d ${ROOT}usr/share/info
		install -d ${ROOT}usr/share/man
		install -d ${ROOT}usr/share/misc
		install -d ${ROOT}usr/src
		install -d -m 1777 ${ROOT}tmp
		install -d -m 1777 ${ROOT}var/tmp
		install -d ${ROOT}var
		install -d ${ROOT}var/db/pkg
		install -d ${ROOT}var/empty
		install -d ${ROOT}var/lib/misc
		install -d ${ROOT}var/lock/subsys
		install -d ${ROOT}var/log/news
		install -d ${ROOT}var/run
		install -d ${ROOT}var/spool
		install -d ${ROOT}var/state
	fi

	# We need to install directories and maybe some dev nodes when building
	# stages, but they cannot be in CONTENTS.
	# Also, we cannot reference $S as binpkg will break so we do this.
	if use build ; then
		local libdirs="$(get_all_libdirs)" dir=
		# Create our multilib dirs - the Makefile has no knowledge of this
		: ${libdirs:=lib}	# it isn't that we don't trust multilib.eclass...
		for dir in ${libdirs}; do
			mkdir -p "${ROOT}${dir}"
			touch "${ROOT}${dir}"/.keep
			mkdir -p "${ROOT}usr/${dir}"
			touch "${ROOT}usr/${dir}"/.keep
			mkdir -p "${ROOT}usr/local/${dir}"
			touch "${ROOT}usr/local/${dir}"/.keep
		done

		# Create symlinks for /lib, /usr/lib, and /usr/local/lib and
		# merge contents of duplicate directories if necessary.
		# Only do this when $ROOT != / since it should only be necessary
		# when merging to an empty $ROOT, and it's not very safe to perform
		# this operation when $ROOT = /.
		if [ "${SYMLINK_LIB}" = yes ] && [ "$ROOT" != / ] ; then
			local prefix libabi=$(get_abi_LIBDIR $DEFAULT_ABI)
			for prefix in "$ROOT"{,usr/,usr/local/} ; do

				[ ! -d "${prefix}lib" ] && rm -f "${prefix}lib" && \
					mkdir -p "${prefix}lib"

				[ ! -d "$prefix$libabi" ] && ln -sf "${prefix}lib"

				[ -h "$prefix$libabi" ] && [ -d "${prefix}lib" ] && \
					[ "$prefix$libabi" -ef "${prefix}lib" ] && continue

				local destdir=$prefix$libabi/ srcdir=${prefix}lib/

				[ -d "$destdir" ] || die "unable to create '$destdir'"
				[ -d "$srcdir" ] || die "unable to create $srcdir"

				mv -f "$srcdir".keep "$destdir".keep 2>/dev/null
				if ! rmdir "$srcdir" 2>/dev/null ; then
					ewarn "merging contents of '$srcdir' into '$destdir':"

					# Move directories if the dest doesn't exist.
					find "$srcdir" -type d -print0 | \
					while read -d $'\0' src ; do

						# If a parent directory of $src has already
						# been merged then it will no longer exist.
						[ -d "$src" ] || continue

						dest=$destdir${src#${srcdir}}
						if [ ! -d "$dest" ] ; then
							if [ -e "$dest" ] ; then
								ewarn "  not overwriting file '$dest'" \
									"with directory '$src'"
								continue
							fi
							mv -f "$src" "$dest" && \
								ewarn "  /${src#${ROOT}} merged" || \
								ewarn "  /${src#${ROOT}} not merged"
						fi
					done

					# Move non-directories.
					find "$srcdir" ! -type d -print0 | \
					while read -d $'\0' src ; do
						dest=$destdir${src#${srcdir}}
						if [ -e "$dest" ] ; then
							if [ -d "$dest" ] ; then
								ewarn "  not overwriting directory '$dest'" \
									"with file '$src'"
							else
								if [ -f "$src" -a ! -s "$src" ] && \
									[ -f "$dest" -a ! -s "$dest" ] ; then
									# Ignore empty files such as '.keep'.
									true
								else
									ewarn "  not overwriting file '$dest'" \
										"with file '$src'"
								fi
							fi
							continue
						fi

						mv -f "$src" "$dest" && \
							ewarn "  /${src#${ROOT}} merged" || \
							ewarn "  /${src#${ROOT}} not merged"
					done
				fi

				rm -rf "${prefix}lib" || \
					die "unable to remove '${prefix}lib'"

				ln -s "$libabi" "${prefix}lib" || \
					die "unable to create '${prefix}lib' symlink"
			done
		fi
	fi
	rm -f "${D}"/usr/share/${PN}/Makefile
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

src_compile() {
	return 0
}

src_install() {
	local libdir="lib"
	[[ ${SYMLINK_LIB} == "yes" ]] && libdir=$(get_abi_LIBDIR "${DEFAULT_ABI}")

	dodir /etc /usr/share/baselayout
	cp -pPR etc/* etc.Linux/* ${D}/etc/ || die
	cp -pPR share.Linux/* ${D}/usr/share/baselayout || die
	
	dodoc ChangeLog

	into /
	dosbin "${FILESDIR}/MAKEDEV"
	dosym ../../sbin/MAKEDEV /usr/sbin/MAKEDEV
	dosym ../sbin/MAKEDEV /dev/MAKEDEV

	# need the makefile in pkg_preinst
	insinto /usr/share/${PN}
	doins Makefile || die

	# Should this belong in another ebuild? Like say binutils?
	# List all the multilib libdirs in /etc/env/04multilib (only if they're
	# actually different from the normal
	if has_multilib_profile || [ $(get_libdir) != "lib" -o -n "${CONF_MULTILIBDIR}" ]; then
		local libdirs="$(get_all_libdirs)" libdirs_env= dir=
		: ${libdirs:=lib}	# it isn't that we don't trust multilib.eclass...
		for dir in ${libdirs}; do
			libdirs_env=${libdirs_env:+$libdirs_env:}/${dir}:/usr/${dir}:/usr/local/${dir}
		done

		# Special-case uglyness... For people updating from lib32 -> lib amd64
		# profiles, keep lib32 in the search path while it's around
		if has_multilib_profile && [ -d "${ROOT}"lib32 -o -d "${ROOT}"lib32 ] && ! hasq lib32 ${libdirs}; then
			libdirs_env="${libdirs_env}:/lib32:/usr/lib32:/usr/local/lib32"
		fi
		echo "LDPATH=\"${libdirs_env}\"" > "${T}"/04multilib
		doenvd "${T}"/04multilib
	fi

	# rc-scripts version for testing of features that *should* be present
	echo "Gentoo Base System release ${PV}" > "${D}"/etc/gentoo-release
}

pkg_postinst() {
	# We installed some files to /usr/share/baselayout instead of /etc to stop
	# (1) overwriting the user's settings
	# (2) screwing things up when attempting to merge files
	# (3) accidentally packaging up personal files with quickpkg
	# If they don't exist then we install them
	for x in master.passwd passwd shadow group fstab ; do
		[ -e "${ROOT}etc/${x}" ] && continue
		[ -e "${ROOT}usr/share/baselayout/${x}" ] || continue
		cp -p "${ROOT}usr/share/baselayout/${x}" "${ROOT}"etc
	done
	for x in shadow ; do
		[ -e "${ROOT}etc/${x}" ] && chmod 0600 "${ROOT}etc/$x"
	done
	# For the bootstrap scenario with an empty /dev, let's fill the
	# sucker with generic crude ... some day we should think about
	# slimming this way down as we've moved on to udev/devfs
	if use build || [ "$ROOT" != "/" ]; then
		if [[ ! -e ${ROOT}/dev/.devfsd && ! -e ${ROOT}/dev/.udev ]] ; then
			echo
			einfo "Making device node tarball (this could take a couple minutes)"
			cd "${ROOT}"/dev || die
			PATH=${ROOT}/sbin:${PATH} create_dev_nodes
		fi
	fi

	# This is also written in src_install (so it's in CONTENTS), but
	# write it here so that the new version is immediately in the file
	# (without waiting for the user to do etc-update)
	rm -f "${ROOT}"/etc/._cfg????_gentoo-release
	local release="${PV}"
	[ "${PR}" != r0 ] && release="${release}-${PR}"
	echo "Gentoo Base System release ${release}" > "${ROOT}"/etc/gentoo-release

	# whine about users that lack passwords #193541
	if [[ -e ${ROOT}/etc/shadow ]] ; then
		local bad_users=$(sed -n '/^[^:]*::/s|^\([^:]*\)::.*|\1|p' "${ROOT}"/etc/shadow)
		if [[ -n ${bad_users} ]] ; then
			echo
			ewarn "The following users lack passwords!"
			ewarn ${bad_users}
		fi
	fi

	# whine about users with invalid shells #215698
	if [[ -e ${ROOT}/etc/passwd ]] ; then
		local bad_shells=$(awk -F: 'system("test -e " $7) { print $1 " - " $7}' /etc/passwd | sort)
		if [[ -n ${bad_shells} ]] ; then
			echo
			ewarn "The following users have non-existent shells!"
			ewarn "${bad_shells}"
		fi
	fi
}
