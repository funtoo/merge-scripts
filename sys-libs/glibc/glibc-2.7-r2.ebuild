# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/glibc/glibc-2.7-r2.ebuild,v 1.18 2009/12/10 01:31:25 vapier Exp $

inherit eutils versionator libtool toolchain-funcs flag-o-matic gnuconfig multilib

DESCRIPTION="GNU libc6 (also called glibc2) C library"
HOMEPAGE="http://www.gnu.org/software/libc/libc.html"

LICENSE="LGPL-2"
KEYWORDS="~amd64 arm hppa ~ia64 ~ppc ppc64 s390 sh ~sparc ~x86"
RESTRICT="strip" # strip ourself #46186
EMULTILIB_PKG="true"

# Configuration variables
RELEASE_VER=$(get_version_component_range 1-3) # major glibc version
BRANCH_UPDATE=$(get_version_component_range 4) # upstream cvs snaps
MANPAGE_VER=""                                 # pregenerated manpages
INFOPAGE_VER=""                                # pregenerated infopages
PATCH_VER="1.7"                                # Gentoo patchset
PATCH_GLIBC_VER=${RELEASE_VER}                 # glibc version in patchset
PORTS_VER=${RELEASE_VER}                       # version of glibc ports addon
LIBIDN_VER=${RELEASE_VER}                      # version of libidn addon
LT_VER=""                                      # version of linuxthreads addon
NPTL_KERN_VER=${NPTL_KERN_VER:-"2.6.9"}        # min kernel version nptl requires
#LT_KERN_VER=${LT_KERN_VER:-"2.4.1"}           # min kernel version linuxthreads requires

IUSE="debug gd glibc-omitfp hardened multilib nls selinux profile vanilla crosscompile_opts_headers-only ${LT_VER:+glibc-compat20 nptl nptlonly}"
S=${WORKDIR}/glibc-${RELEASE_VER}

# Here's how the cross-compile logic breaks down ...
#  CTARGET - machine that will target the binaries
#  CHOST   - machine that will host the binaries
#  CBUILD  - machine that will build the binaries
# If CTARGET != CHOST, it means you want a libc for cross-compiling.
# If CHOST != CBUILD, it means you want to cross-compile the libc.
#  CBUILD = CHOST = CTARGET    - native build/install
#  CBUILD != (CHOST = CTARGET) - cross-compile a native build
#  (CBUILD = CHOST) != CTARGET - libc for cross-compiler
#  CBUILD != CHOST != CTARGET  - cross-compile a libc for a cross-compiler
# For install paths:
#  CHOST = CTARGET  - install into /
#  CHOST != CTARGET - install into /usr/CTARGET/

export CBUILD=${CBUILD:-${CHOST}}
export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY/cross-} != ${CATEGORY} ]] ; then
		export CTARGET=${CATEGORY/cross-}
	fi
fi

[[ ${CTARGET} == hppa* ]] && NPTL_KERN_VER=${NPTL_KERN_VER/2.6.9/2.6.20}

is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}
alt_libdir() {
	if is_crosscompile ; then
		echo /usr/${CTARGET}/$(get_libdir)
	else
		echo /$(get_libdir)
	fi
}

if is_crosscompile ; then
	SLOT="${CTARGET}-2.2"
else
	# Why SLOT 2.2 you ask yourself while sippin your tea ?
	# Everyone knows 2.2 > 0, duh.
	SLOT="2.2"
	PROVIDE="virtual/libc"
fi

# General: We need a new-enough binutils for as-needed
# arch: we need to make sure our binutils/gcc supports TLS
DEPEND=">=sys-devel/gcc-3.4.4
	arm? ( >=sys-devel/binutils-2.16.90 >=sys-devel/gcc-4.1.0 )
	ppc? ( >=sys-devel/gcc-4.1.0 )
	ppc64? ( >=sys-devel/gcc-4.1.0 )
	>=sys-devel/binutils-2.15.94
	${LT_VER:+nptl? (} >=sys-kernel/linux-headers-${NPTL_KERN_VER} ${LT_VER:+)}
	>=sys-devel/gcc-config-1.3.12
	>=app-misc/pax-utils-0.1.10
	virtual/os-headers
	nls? ( sys-devel/gettext )
	>=sys-apps/sandbox-1.2.18.1-r2
	>=sys-apps/portage-2.1.2
	selinux? ( sys-libs/libselinux )"
RDEPEND="nls? ( sys-devel/gettext )
	selinux? ( sys-libs/libselinux )"

if [[ ${CATEGORY/cross-} != ${CATEGORY} ]] ; then
	DEPEND="${DEPEND} !crosscompile_opts_headers-only? ( ${CATEGORY}/gcc )"
	[[ ${CATEGORY} == *-linux* ]] && DEPEND="${DEPEND} ${CATEGORY}/linux-headers"
else
	DEPEND="${DEPEND} >=sys-libs/timezone-data-2007c"
	RDEPEND="${RDEPEND} sys-libs/timezone-data"
fi

SRC_URI=$(
	upstream_uris() {
		echo mirror://gnu/glibc/$1 ftp://sources.redhat.com/pub/glibc/{releases,snapshots}/$1
	}
	gentoo_uris() {
		local devspace="HTTP~vapier/dist/URI HTTP~azarah/glibc/URI"
		devspace=${devspace//HTTP/http://dev.gentoo.org/}
		echo mirror://gentoo/$1 ${devspace//URI/$1}
	}

	upstream_uris glibc-${RELEASE_VER}.tar.bz2
	upstream_uris glibc-libidn-${RELEASE_VER}.tar.bz2

	[[ -n ${PORTS_VER}     ]] && upstream_uris glibc-ports-${PORTS_VER}.tar.bz2
	[[ -n ${LT_VER}        ]] && upstream_uris glibc-linuxthreads-${LT_VER}.tar.bz2
	[[ -n ${BRANCH_UPDATE} ]] && gentoo_uris glibc-${RELEASE_VER}-branch-update-${BRANCH_UPDATE}.patch.bz2
	[[ -n ${PATCH_VER}     ]] && gentoo_uris glibc-${PATCH_GLIBC_VER}-patches-${PATCH_VER}.tar.bz2
	[[ -n ${MANPAGE_VER}   ]] && gentoo_uris glibc-manpages-${MANPAGE_VER}.tar.bz2
	[[ -n ${INFOPAGE_VER}  ]] && gentoo_uris glibc-infopages-${INFOPAGE_VER}.tar.bz2
)

# eblit-include [--skip] <function> [version]
eblit-include() {
	local skipable=false
	[[ $1 == "--skip" ]] && skipable=true && shift

	local e v func=$1 ver=$2
	[[ -z ${func} ]] && die "Usage: eblit-include <function> [version]"
	for v in ${ver:+-}${ver} -${PVR} -${PV} "" ; do
		e="${FILESDIR}/eblits/${func}${v}.eblit"
		if [[ -e ${e} ]] ; then
			source "${e}"
			return 0
		fi
	done
	${skipable} && return 0
	die "Could not locate requested eblit '${func}' in ${FILESDIR}/eblits/"
}

# eblit-run-maybe <function>
# run the specified function if it is defined
eblit-run-maybe() {
	[[ $(type -t "$@") == "function" ]] && "$@"
}

# eblit-run <function> [version]
# aka: src_unpack() { eblit-run src_unpack ; }
eblit-run() {
	eblit-include --skip common "${*:2}"
	eblit-include "$@"
	eblit-run-maybe eblit-$1-pre
	eblit-${PN}-$1 || die
	eblit-run-maybe eblit-$1-post
}

src_unpack()  { eblit-run src_unpack  ; }
src_compile() { eblit-run src_compile ; }
src_test()    { eblit-run src_test    ; }
src_install() { eblit-run src_install ; }

eblit-src_unpack-post() {
	if use hardened ; then
		cd "${S}"
		einfo "Patching to get working PIE binaries on PIE (hardened) platforms"
		gcc-specs-pie && epatch "${FILESDIR}"/2.5/glibc-2.5-hardened-pie.patch
		epatch "${FILESDIR}"/2.5/glibc-2.5-hardened-configure-picdefault.patch
		epatch "${FILESDIR}"/2.7/glibc-2.7-hardened-inittls-nosysenter.patch

		einfo "Installing Hardened Gentoo SSP handler"
		cp -f "${FILESDIR}"/2.6/glibc-2.6-gentoo-stack_chk_fail.c \
			debug/stack_chk_fail.c || die

		if use debug ; then
			# When using Hardened Gentoo stack handler, have smashes dump core for
			# analysis - debug only, as core could be an information leak
			# (paranoia).
			sed -i \
				-e '/^CFLAGS-backtrace.c/ iCFLAGS-stack_chk_fail.c = -DSSP_SMASH_DUMPS_CORE' \
				debug/Makefile \
				|| die "Failed to modify debug/Makefile for debug stack handler"
		fi

		# Build nscd with ssp-all
		sed -i \
			-e 's:-fstack-protector$:-fstack-protector-all:' \
			nscd/Makefile \
			|| die "Failed to ensure nscd builds with ssp-all"
	fi
}

pkg_setup() {
	# prevent native builds from downgrading ... maybe update to allow people
	# to change between diff -r versions ? (2.3.6-r4 -> 2.3.6-r2)
	if [[ ${ROOT} == "/" ]] && [[ ${CBUILD} == ${CHOST} ]] && [[ ${CHOST} == ${CTARGET} ]] ; then
		if has_version '>'${CATEGORY}/${PF} ; then
			eerror "Sanity check to keep you from breaking your system:"
			eerror " Downgrading glibc is not supported and a sure way to destruction"
			die "aborting to save your system"
		fi

		# Check for broken kernels #262698
		cd "${T}"
		printf '#include <pwd.h>\nint main(){return getpwuid(0)==0;}\n' > kern-clo-test.c
		emake kern-clo-test || die
		if ! ./kern-clo-test ; then
			eerror "Your patched vendor kernel is broken.  You need to get an"
			eerror "update from whoever is providing the kernel to you."
			eerror "http://sourceware.org/bugzilla/show_bug.cgi?id=5227"
			die "keeping your system alive, say thank you"
		fi
	fi

	# users have had a chance to phase themselves, time to give em the boot
	if [[ -e ${ROOT}/etc/locale.gen ]] && [[ -e ${ROOT}/etc/locales.build ]] ; then
		eerror "You still haven't deleted ${ROOT}/etc/locales.build."
		eerror "Do so now after making sure ${ROOT}/etc/locale.gen is kosher."
		die "lazy upgrader detected"
	fi

	if [[ ${CTARGET} == i386-* ]] ; then
		eerror "i386 CHOSTs are no longer supported."
		eerror "Chances are you don't actually want/need i386."
		eerror "Please read http://www.gentoo.org/doc/en/change-chost.xml"
		die "please fix your CHOST"
	fi

	if [[ -n ${LT_VER} ]] ; then
		if use nptlonly && ! use nptl ; then
			eerror "If you want nptlonly, add nptl to your USE too ;p"
			die "nptlonly without nptl"
		fi
	fi

	if [[ -e /proc/xen ]] && [[ $(tc-arch) == "x86" ]] && ! is-flag -mno-tls-direct-seg-refs ; then
		ewarn "You are using Xen but don't have -mno-tls-direct-seg-refs in your CFLAGS."
		ewarn "This will result in a 50% performance penalty, which is probably not what you want."
	fi

	use hardened && ! gcc-specs-pie && \
		ewarn "PIE hardening not applied, as your compiler doesn't default to PIE"

	export LC_ALL=C #252802
}

fix_lib64_symlinks() {
	# the original Gentoo/AMD64 devs decided that since 64bit is the native
	# bitdepth for AMD64, lib should be used for 64bit libraries. however,
	# this ignores the FHS and breaks multilib horribly... especially
	# since it wont even work without a lib64 symlink anyways. *rolls eyes*
	# see bug 59710 for more information.
	# Travis Tilley <lv@gentoo.org> (08 Aug 2004)
	if [ -L ${ROOT}/lib64 ] ; then
		ewarn "removing /lib64 symlink and moving lib to lib64..."
		ewarn "dont hit ctrl-c until this is done"
		rm ${ROOT}/lib64
		# now that lib64 is gone, nothing will run without calling ld.so
		# directly. luckily the window of brokenness is almost non-existant
		use amd64 && /lib/ld-linux-x86-64.so.2 /bin/mv ${ROOT}/lib ${ROOT}/lib64
		use ppc64 && /lib/ld64.so.1 /bin/mv ${ROOT}/lib ${ROOT}/lib64
		# all better :)
		ldconfig
		ln -s lib64 ${ROOT}/lib
		einfo "done! :-)"
		einfo "fixed broken lib64/lib symlink in ${ROOT}"
	fi
	if [ -L ${ROOT}/usr/lib64 ] ; then
		rm ${ROOT}/usr/lib64
		mv ${ROOT}/usr/lib ${ROOT}/usr/lib64
		ln -s lib64 ${ROOT}/usr/lib
		einfo "fixed broken lib64/lib symlink in ${ROOT}/usr"
	fi
	if [ -L ${ROOT}/usr/X11R6/lib64 ] ; then
		rm ${ROOT}/usr/X11R6/lib64
		mv ${ROOT}/usr/X11R6/lib ${ROOT}/usr/X11R6/lib64
		ln -s lib64 ${ROOT}/usr/X11R6/lib
		einfo "fixed broken lib64/lib symlink in ${ROOT}/usr/X11R6"
	fi
}

pkg_preinst() {
	# nothing to do if just installing headers
	just_headers && return

	# PPC64+others may want to eventually be added to this logic if they
	# decide to be multilib compatible and FHS compliant. note that this
	# chunk of FHS compliance only applies to 64bit archs where 32bit
	# compatibility is a major concern (not IA64, for example).

	# amd64's 2005.0 is the first amd64 profile to not need this code.
	# 2005.0 is setup properly, and this is executed as part of the
	# 2004.3 -> 2005.0 upgrade script.
	# It can be removed after 2004.3 has been purged from portage.
	{ use amd64 || use ppc64; } && [ "$(get_libdir)" == "lib64" ] && ! has_multilib_profile && fix_lib64_symlinks

	# it appears that /lib/tls is sometimes not removed.  See bug
	# 69258 for more info.
	if [[ -d ${ROOT}/$(alt_libdir)/tls ]] && [[ ! -d ${D}/$(alt_libdir)/tls ]] ; then
		ewarn "nptlonly or -nptl in USE, removing /${ROOT}$(alt_libdir)/tls..."
		rm -r "${ROOT}"/$(alt_libdir)/tls || die
	fi

	# Shouldnt need to keep this updated
	[[ -e ${ROOT}/etc/locale.gen ]] && rm -f "${D}"/etc/locale.gen

	# simple test to make sure our new glibc isnt completely broken.
	# make sure we don't test with statically built binaries since
	# they will fail.  also, skip if this glibc is a cross compiler.
	[[ ${ROOT} != "/" ]] && return 0
	[[ -d ${D}/$(get_libdir) ]] || return 0
	cd / #228809
	local x striptest
	for x in date env ls true uname ; do
		x=$(type -p ${x})
		[[ -z ${x} ]] && continue
		striptest=$(LC_ALL="C" file -L ${x} 2>/dev/null)
		[[ -z ${striptest} ]] && continue
		[[ ${striptest} == *"statically linked"* ]] && continue
		"${D}"/$(get_libdir)/ld-*.so \
			--library-path "${D}"/$(get_libdir) \
			${x} > /dev/null \
			|| die "simple run test (${x}) failed"
	done
}

pkg_postinst() {
	# nothing to do if just installing headers
	just_headers && return

	if ! tc-is-cross-compiler && [[ -x ${ROOT}/usr/sbin/iconvconfig ]] ; then
		# Generate fastloading iconv module configuration file.
		"${ROOT}"/usr/sbin/iconvconfig --prefix="${ROOT}"
	fi

	if ! is_crosscompile && [[ ${ROOT} == "/" ]] ; then
		# Reload init ...
		/sbin/telinit U

		# if the host locales.gen contains no entries, we'll install everything
		local locale_list="${ROOT}etc/locale.gen"
		if [[ -z $(locale-gen --list --config "${locale_list}") ]] ; then
			ewarn "Generating all locales; edit /etc/locale.gen to save time/space"
			locale_list="${ROOT}usr/share/i18n/SUPPORTED"
		fi
		local x jobs
		for x in ${MAKEOPTS} ; do [[ ${x} == -j* ]] && jobs=${x#-j} ; done
		locale-gen -j ${jobs:-1} --config "${locale_list}"
	fi
}
