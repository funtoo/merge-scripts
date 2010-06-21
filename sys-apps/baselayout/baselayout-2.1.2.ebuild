# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit multilib

DESCRIPTION="Filesystem baselayout and init scripts"
HOMEPAGE="http://www.funtoo.org/"
SRC_URI="http://www.funtoo.org/archive/baselayout/baselayout-2.1.1.tar.bz2"
S=$WORKDIR/baselayout-2.1.1

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc sparc-fbsd x86 x86-fbsd"
IUSE="build"

PDEPEND="sys-apps/openrc"

pkg_preinst() {

	modfix

	# We need to install directories and maybe some dev nodes when building
	# stages, but they cannot be in CONTENTS.
	# Also, we cannot reference $S as binpkg will break so we do this.
	if use build ; then
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
}

src_compile() {
	return 0
}

modfix() {
	local mod

	# We want to move any old modprobe.d conf files to the new file name so
	# config file protection works correctly.

	for mod in i386 aliases 
	do
		if [ -e $ROOT/etc/modprobe.d/$mod ] 
		then
			mv $ROOT/etc/modprobe.d/$mod $ROOT/etc/modprobe.d/${mod}.conf || die "mv failed"
		fi
	done

}

src_install() {
	local libdir="lib"
	local rcscripts_dir="/lib/rcscripts"

	if [[ ${SYMLINK_LIB} == "yes" ]]; then
		libdir=$(get_abi_LIBDIR "${DEFAULT_ABI}")
		rcscripts_dir="/${libdir}/rcscripts"
	fi
	
	dodir /etc /usr/share/baselayout
	cp -pPR etc/* etc.Linux/* ${D}/etc/ || die
	cp -pPR share.Linux/* ${D}/usr/share/baselayout || die

	einfo "Creating directories..."

	local libdirs="$(get_all_libdirs)" dir=
	# Create our multilib dirs 
	# it isn't that we don't trust multilib.eclass...
	: ${libdirs:=lib}	
	for dir in ${libdirs}; do
		keepdir /${dir}
		keepdir /usr/${dir}
		keepdir /usr/local/${dir}
	done

	keepdir /usr
	keepdir /usr/local
	keepdir /boot
	keepdir /etc/conf.d
	keepdir /etc/cron.daily
	keepdir /etc/cron.hourly
	keepdir /etc/cron.monthly
	keepdir /etc/cron.weekly
	keepdir /etc/env.d
	keepdir /etc/modules.autoload.d
	keepdir /etc/modules.d
	keepdir /etc/opt
	keepdir /etc/profile.d
	keepdir /etc/portage
	keepdir /home
	keepdir ${rcscripts_dir}
	keepdir /mnt
	keepdir /mnt/cdrom
	keepdir /mnt/floppy
	keepdir /opt
	keepdir /sbin
	keepdir /usr/bin
	keepdir /usr/include
	keepdir /usr/include/asm
	keepdir /usr/include/linux
	keepdir /usr/local/bin
	keepdir /usr/local/games
	keepdir /usr/local/sbin
	keepdir /usr/local/share
	keepdir /usr/local/share/doc

	keepdir /usr/local/share/man
	dosym /usr/share/man /usr/local/share/man

	keepdir /usr/local/src
	keepdir /usr/sbin
	keepdir /usr/share/doc
	keepdir /usr/share/info
	keepdir /usr/share/man
	keepdir /usr/share/misc
	keepdir /usr/src
	
	keepdir /var
	
	keepdir /var/adm
	keepdir /var/spool/lpd
	keepdir /var/spool/news
	keepdir /var/spool/uucp

	keepdir /var/db/pkg
	keepdir /var/empty
	keepdir /var/lib/misc
	keepdir /var/lock/subsys
	keepdir /var/log/news
	keepdir /var/run
	keepdir /var/spool
	keepdir /var/state

	diropts -m 1777
	keepdir /tmp /var/tmp

	diropts -o root -g uucp -m0775 /var/lock
	keepdir /var/lock

	diropts -m0700
	keepdir /root
	
	if [ "$ROOT" != "/" ]
	then
		# stuff we can only write in if unmounted; only try if ROOT!=/
		keepdir /proc
		keepdir /sys
		keepdir /dev
		keepdir /dev/pts
		keepdir /dev/shm
	fi

	dodoc ChangeLog

	into /
	dosbin "${FILESDIR}/MAKEDEV"
	dosym ../../sbin/MAKEDEV /usr/sbin/MAKEDEV

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
	echo "Funtoo Linux - baselayout ${PV}" > "${D}"/etc/gentoo-release
}

pkg_postinst() {
	local x

	# templates installed to /usr/share/baselayout and copied into place if they
	# don't exist in /etc.

	for x in master.passwd passwd shadow group fstab ; do
		[ -e "${ROOT}etc/${x}" ] && continue
		[ -e "${ROOT}usr/share/baselayout/${x}" ] || continue
		cp -p "${ROOT}usr/share/baselayout/${x}" "${ROOT}"etc
	done

	# carefully set perms for shadow to prevent non-root users from viewing
	# encrypted password files.
	
	for x in shadow ; do
		[ -e "${ROOT}etc/${x}" ] && chmod 0600 "${ROOT}etc/$x"
	done

	# create minimal set of device nodes required for boot, if they do not
	# already exist. The chmod commonds are also run every time to ensure that
	# proper permissions are set on the device nodes, even if they already
	# exist.

	# Below, we want to create a base set of device nodes that will be suitable
	# for chrooting, for OpenVZ, for emergency/initial booting without udev,
	# and for stage builds. Some ebuilds require urandom to exist.

	cd "${ROOT}"/dev || die

	[ -e console ] || mknod console c 5 1 || die
	chmod 600 console

	[ -e null ] || mknod null c 1 3 || die
	chmod 777 null

	[ -e tty ] || mknod tty c 5 0 || die
	chmod 666 tty

	[ -e ttyp0 ] || mknod ttyp0 c 3 0 || die
	chmod 644 ttyp0

	[ -e ptyp0 ] || mknod ptyp0 c 2 0 || die
	chmod 644 ptyp0

	[ -e ptmx ] || mknod ptmx c 5 2 || die
	chmod 666 ptmx

	[ -e tty0 ] || mknod tty0 c 4 0 || die
	chmod 666 tty0
	
	[ -e urandom ] || mknod urandom c 1 9 || die
	chmod 666 urandom

	[ -e random ] || mknod random c 1 8 || die
	chmod 666 random

	[ -e zero ] || mknod zero c 1 5 || die
	chmod 666 zero

	for x in 0 1 2 3
	do
		[ -e ttyS${x} ] || mknod ttyS${x} c 4 $(( 64 + $x )) || die
		chmod 600 ttyS${x}
	done
}
