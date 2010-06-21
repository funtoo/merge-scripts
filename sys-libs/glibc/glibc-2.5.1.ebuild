# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/glibc/glibc-2.5.1.ebuild,v 1.5 2009/12/10 01:31:25 vapier Exp $

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

# need to wait for proper ports/linuxthreads release
KEYWORDS="" #~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"

BRANCH_UPDATE=""

# Generated man pages
GLIBC_MANPAGE_VERSION="none"

# Generated stuff in manual subdir
GLIBC_INFOPAGE_VERSION="none"

# Gentoo patchset
PATCH_VER="1.0"

GENTOO_TOOLCHAIN_BASE_URI="mirror://gentoo"
GENTOO_TOOLCHAIN_DEV_URI="http://dev.gentoo.org/~azarah/glibc/XXX http://dev.gentoo.org/~vapier/dist/XXX"

### PUNT OUT TO ECLASS?? ###
inherit eutils versionator libtool toolchain-funcs flag-o-matic gnuconfig multilib

DESCRIPTION="GNU libc6 (also called glibc2) C library"
HOMEPAGE="http://www.gnu.org/software/libc/libc.html"
LICENSE="LGPL-2"

IUSE="build debug nls nptl nptlonly hardened multilib selinux glibc-omitfp profile glibc-compat20"

export CBUILD=${CBUILD:-${CHOST}}
export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY/cross-} != ${CATEGORY} ]] ; then
		export CTARGET=${CATEGORY/cross-}
	fi
fi
if [[ ${CTARGET} == ${CHOST} ]] ; then
	PROVIDE="virtual/libc"
fi

is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}
just_headers() {
	is_crosscompile && use crosscompile_opts_headers-only
}

GLIBC_RELEASE_VER=$(get_version_component_range 1-3)

# Don't set this to :-, - allows BRANCH_UPDATE=""
BRANCH_UPDATE=${BRANCH_UPDATE-$(get_version_component_range 4)}
GLIBC_PORTS_VER="2.5" #${GLIBC_RELEASE_VER}
#GLIBC_PORTS_VER="20060925"
GLIBC_LT_VER="2.5" #${GLIBC_RELEASE_VER}
#GLIBC_LT_VER="20060605"

# (Recent snapshots fails with 2.6.5 and earlier with NPTL)
NPTL_KERNEL_VERSION=${NPTL_KERNEL_VERSION:-"2.6.9"}
LT_KERNEL_VERSION=${LT_KERNEL_VERSION:-"2.4.1"}

[[ ${CTARGET} == hppa* ]] && NPTL_KERNEL_VERSION=${NPTL_KERNEL_VERSION:-2.6.20}

### SRC_URI ###

# This function handles the basics of setting the SRC_URI for a glibc ebuild.
# To use, set SRC_URI with:
#
#	SRC_URI="$(get_glibc_src_uri)"
#
# Other than the variables normally set by portage, this function's behavior
# can be altered by setting the following:
#
#	GENTOO_TOOLCHAIN_BASE_URI
#			This sets the base URI for all gentoo-specific patch files. Note
#			that this variable is only important for a brief period of time,
#			before your source files get picked up by mirrors. However, it is
#			still highly suggested that you keep files in this location
#			available.
#
#	BRANCH_UPDATE
#			If set, this variable signals that we should be using the main
#			release tarball (determined by ebuild version) and applying a
#			CVS branch update patch against it. The location of this branch
#			update patch is assumed to be in ${GENTOO_TOOLCHAIN_BASE_URI}.
#			Just like with SNAPSHOT, this variable is ignored if the ebuild
#			has a _pre suffix.
#
#	PATCH_VER
#	PATCH_GLIBC_VER
#			This should be set to the version of the gentoo patch tarball.
#			The resulting filename of this tarball will be:
#			glibc-${PATCH_GLIBC_VER:-${GLIBC_RELEASE_VER}}-patches-${PATCH_VER}.tar.bz2
#
#	GLIBC_MANPAGE_VERSION
#	GLIBC_INFOPAGE_VERSION
#			The version of glibc for which we will download pages. This will
#			default to ${GLIBC_RELEASE_VER}, but we may not want to pre-generate man pages
#			for prerelease test ebuilds for example. This allows you to
#			continue using pre-generated manpages from the last stable release.
#			If set to "none", this will prevent the downloading of manpages,
#			which is useful for individual library targets.
#
get_glibc_src_uri() {
	GENTOO_TOOLCHAIN_BASE_URI=${GENTOO_TOOLCHAIN_BASE_URI:-"mirror://gentoo"}

	GLIBC_SRC_URI="mirror://gnu/glibc/glibc-${GLIBC_RELEASE_VER}.tar.bz2
	               mirror://gnu/glibc/glibc-ports-${GLIBC_PORTS_VER}.tar.bz2
	               ftp://sources.redhat.com/pub/glibc/snapshots/glibc-ports-${GLIBC_PORTS_VER}.tar.bz2
	               mirror://gnu/glibc/glibc-libidn-${GLIBC_RELEASE_VER}.tar.bz2"

	if [[ -n ${BRANCH_UPDATE} ]] ; then
		GLIBC_SRC_URI="${GLIBC_SRC_URI}
			${GENTOO_TOOLCHAIN_BASE_URI}/glibc-${GLIBC_RELEASE_VER}-branch-update-${BRANCH_UPDATE}.patch.bz2
			${GENTOO_TOOLCHAIN_DEV_URI//XXX/glibc-${GLIBC_RELEASE_VER}-branch-update-${BRANCH_UPDATE}.patch.bz2}"
	fi

	if [[ -n ${PATCH_VER} ]] ; then
		GLIBC_SRC_URI="${GLIBC_SRC_URI}
			${GENTOO_TOOLCHAIN_BASE_URI}/glibc-${PATCH_GLIBC_VER:-${GLIBC_RELEASE_VER}}-patches-${PATCH_VER}.tar.bz2
			${GENTOO_TOOLCHAIN_DEV_URI//XXX/glibc-${PATCH_GLIBC_VER:-${GLIBC_RELEASE_VER}}-patches-${PATCH_VER}.tar.bz2}"
	fi

	if [[ ${GLIBC_MANPAGE_VERSION} != "none" ]] ; then
		GLIBC_SRC_URI="${GLIBC_SRC_URI}
			${GENTOO_TOOLCHAIN_BASE_URI}/glibc-manpages-${GLIBC_MANPAGE_VERSION:-${GLIBC_RELEASE_VER}}.tar.bz2
			${GENTOO_TOOLCHAIN_DEV_URI//XXX/glibc-manpages-${GLIBC_MANPAGE_VERSION:-${GLIBC_RELEASE_VER}}.tar.bz2}"
	fi

	if [[ ${GLIBC_INFOPAGE_VERSION} != "none" ]] ; then
		GLIBC_SRC_URI="${GLIBC_SRC_URI}
			${GENTOO_TOOLCHAIN_BASE_URI}/glibc-infopages-${GLIBC_INFOPAGE_VERSION:-${GLIBC_RELEASE_VER}}.tar.bz2
			${GENTOO_TOOLCHAIN_DEV_URI//XXX/glibc-infopages-${GLIBC_INFOPAGE_VERSION:-${GLIBC_RELEASE_VER}}.tar.bz2}"
	fi

	if [[ -n ${GLIBC_LT_VER} ]] ; then
		GLIBC_SRC_URI="${GLIBC_SRC_URI}
			mirror://gnu/glibc/glibc-linuxthreads-${GLIBC_LT_VER}.tar.bz2
			ftp://sources.redhat.com/pub/glibc/snapshots/glibc-linuxthreads-${GLIBC_LT_VER}.tar.bz2"
	fi

	echo "${GLIBC_SRC_URI}"
}

SRC_URI=$(get_glibc_src_uri)
S=${WORKDIR}/glibc-${GLIBC_RELEASE_VER}

### EXPORTED FUNCTIONS ###
unpack_addon() {
	local addon=$1 ver=${2:-${GLIBC_RELEASE_VER}}
	unpack glibc-${addon}-${ver}.tar.bz2
	mv glibc-${addon}-${ver} ${addon} || die
}
toolchain-glibc_src_unpack() {
	# Check NPTL support _before_ we unpack things to save some time
	want_nptl && check_nptl_support

	unpack glibc-${GLIBC_RELEASE_VER}.tar.bz2

	cd "${S}"
	[[ -n ${GLIBC_LT_VER} ]] && unpack glibc-linuxthreads-${GLIBC_LT_VER}.tar.bz2
	unpack_addon libidn
	unpack_addon ports ${GLIBC_PORTS_VER}

	if [[ -n ${PATCH_VER} ]] ; then
		cd "${WORKDIR}"
		unpack glibc-${PATCH_GLIBC_VER:-${GLIBC_RELEASE_VER}}-patches-${PATCH_VER}.tar.bz2
		# pull out all the addons
		local d
		for d in extra/*/configure ; do
			mv "${d%/configure}" "${S}" || die "moving ${d}"
		done
	fi

	# XXX: We should do the branchupdate, before extracting the manpages and
	# infopages else it does not help much (mtimes change if there is a change
	# to them with branchupdate)
	if [[ -n ${BRANCH_UPDATE} ]] ; then
		cd "${S}"
		epatch "${DISTDIR}"/glibc-${GLIBC_RELEASE_VER}-branch-update-${BRANCH_UPDATE}.patch.bz2

		# Snapshot date patch
		einfo "Patching version to display snapshot date ..."
		sed -i -e "s:\(#define RELEASE\).*:\1 \"${BRANCH_UPDATE}\":" version.h
	fi

	if [[ ${GLIBC_MANPAGE_VERSION} != "none" ]] ; then
		cd "${WORKDIR}"
		unpack glibc-manpages-${GLIBC_MANPAGE_VERSION:-${GLIBC_RELEASE_VER}}.tar.bz2
	fi

	if [[ ${GLIBC_INFOPAGE_VERSION} != "none" ]] ; then
		cd "${S}"
		unpack glibc-infopages-${GLIBC_INFOPAGE_VERSION:-${GLIBC_RELEASE_VER}}.tar.bz2
	fi

	if [[ -n ${PATCH_VER} ]] ; then
		cd "${S}"
		EPATCH_MULTI_MSG="Applying Gentoo Glibc Patchset ${PATCH_GLIBC_VER:-${GLIBC_RELEASE_VER}}-${PATCH_VER} ..." \
		EPATCH_EXCLUDE=${GLIBC_PATCH_EXCLUDE} \
		EPATCH_SUFFIX="patch" \
		ARCH=$(tc-arch) \
		epatch "${WORKDIR}"/patches

		# tag, glibc is it
		[[ -e csu/Banner ]] && die "need new banner location"
		echo "Gentoo patchset ${PATCH_VER}" > csu/Banner
	fi

	if use hardened ; then
		cd "${S}"
		einfo "Patching to get working PIE binaries on PIE (hardened) platforms"
		gcc-specs-pie && epatch "${FILESDIR}"/2.5/glibc-2.5-hardened-pie.patch
		epatch "${FILESDIR}"/2.5/glibc-2.5-hardened-configure-picdefault.patch
		epatch "${FILESDIR}"/2.5/glibc-2.5-hardened-inittls-nosysenter.patch

		einfo "Installing Hardened Gentoo SSP handler"
		cp -f "${FILESDIR}"/2.5/glibc-2.5-gentoo-stack_chk_fail.c \
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

	gnuconfig_update
}

toolchain-glibc_src_compile() {
	echo
	local v
	for v in ABI CBUILD CHOST CTARGET CBUILD_OPT CTARGET_OPT CC CFLAGS ; do
		einfo " $(printf '%15s' ${v}:)   ${!v}"
	done
	echo

	if want_linuxthreads ; then
		glibc_do_configure linuxthreads
		einfo "Building GLIBC with linuxthreads..."
		make PARALLELMFLAGS="${MAKEOPTS}" || die "make for ${ABI} failed"
	fi
	if want_nptl ; then
		# ... and then do the optional nptl build
		unset LD_ASSUME_KERNEL
		glibc_do_configure nptl
		einfo "Building GLIBC with NPTL..."
		make PARALLELMFLAGS="${MAKEOPTS}" || die "make for ${ABI} failed"
	fi
}

toolchain-glibc_headers_compile() {
	local GBUILDDIR=${WORKDIR}/build-${ABI}-${CTARGET}-headers
	mkdir -p "${GBUILDDIR}"
	cd "${GBUILDDIR}"

	# Pick out the correct location for build headers
	local myconf="--disable-sanity-checks --enable-hacker-mode"
	myconf="${myconf}
		--enable-add-ons=nptl,ports
		--without-cvs
		--enable-bind-now
		--build=${CBUILD_OPT:-${CBUILD}}
		--host=${CTARGET_OPT:-${CTARGET}}
		--with-headers=$(alt_build_headers)
		--prefix=/usr
		${EXTRA_ECONF}"

	einfo "Configuring GLIBC headers with: ${myconf// /\n\t\t}"
	CC=gcc \
	CFLAGS="-O1 -pipe" \
	"${S}"/configure ${myconf} || die "failed to configure glibc"
}

toolchain-glibc_src_test() {
	cd "${WORKDIR}"/build-${ABI}-${CTARGET}-$1 || die "cd build-${ABI}-${CTARGET}-$1"
	unset LD_ASSUME_KERNEL
	make check && return 0
	einfo "make check failed - re-running with --keep-going to get the rest of the results"
	make -k check
	ewarn "make check failed for ${ABI}-${CTARGET}-$1"
	return 1
}

toolchain-glibc_pkg_preinst() {
	# PPC64+others may want to eventually be added to this logic if they
	# decide to be multilib compatible and FHS compliant. note that this
	# chunk of FHS compliance only applies to 64bit archs where 32bit
	# compatibility is a major concern (not IA64, for example).

	# amd64's 2005.0 is the first amd64 profile to not need this code.
	# 2005.0 is setup properly, and this is executed as part of the
	# 2004.3 -> 2005.0 upgrade script.
	# It can be removed after 2004.3 has been purged from portage.
	{ use amd64 || use ppc64; } && [ "$(get_libdir)" == "lib64" ] && ! has_multilib_profile && fix_lib64_symlinks

	# it appears that /lib/tls is sometimes not removed. See bug
	# 69258 for more info.
	if [[ -d ${ROOT}/$(alt_libdir)/tls ]] && ! { want_nptl && want_linuxthreads; }; then
		addwrite "${ROOT}"/$(alt_libdir)/
		ewarn "nptlonly or -nptl in USE, removing /${ROOT}$(alt_libdir)/tls..."
		rm -r "${ROOT}"/$(alt_libdir)/tls || die
	fi

	# Shouldnt need to keep this updated
	[[ -e ${ROOT}/etc/locale.gen ]] && rm -f "${D}"/etc/locale.gen

	# simple test to make sure our new glibc isnt completely broken.
	# make sure we don't test with statically built binaries since
	# they will fail.  also, skip if this glibc is a cross compiler.
	[[ ${ROOT} != "/" ]] && return 0
	is_crosscompile && return 0
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

toolchain-glibc_src_install() {
	# These should not be set, else the
	# zoneinfo do not always get installed ...
	unset LANGUAGE LANG LC_ALL

	local GBUILDDIR
	if want_linuxthreads ; then
		GBUILDDIR=${WORKDIR}/build-${ABI}-${CTARGET}-linuxthreads
	else
		GBUILDDIR=${WORKDIR}/build-${ABI}-${CTARGET}-nptl
	fi

	local install_root=${D}
	is_crosscompile && install_root="${install_root}/usr/${CTARGET}"
	if want_linuxthreads ; then
		cd "${WORKDIR}"/build-${ABI}-${CTARGET}-linuxthreads
		einfo "Installing GLIBC ${ABI} with linuxthreads ..."
		make PARALLELMFLAGS="${MAKEOPTS}" \
			install_root="${install_root}" \
			install || die
	else # nptlonly
		cd "${WORKDIR}"/build-${ABI}-${CTARGET}-nptl
		einfo "Installing GLIBC ${ABI} with NPTL ..."
		make PARALLELMFLAGS="${MAKEOPTS}" \
			install_root="${install_root}" \
			install || die
	fi

	if is_crosscompile ; then
		# punt all the junk not needed by a cross-compiler
		cd "${D}"/usr/${CTARGET} || die
		rm -rf ./{,usr/}{bin,etc,sbin,share} ./{,usr/}*/{gconv,misc}
	fi

	if want_linuxthreads && want_nptl ; then
		einfo "Installing NPTL to $(alt_libdir)/tls/..."
		cd "${WORKDIR}"/build-${ABI}-${CTARGET}-nptl
		dodir $(alt_libdir)/tls $(alt_usrlibdir)/nptl

		local l src_lib
		for l in libc libm librt libpthread libthread_db ; do
			# take care of shared lib first ...
			l=${l}.so
			if [[ -e ${l} ]] ; then
				src_lib=${l}
			else
				src_lib=$(eval echo */${l})
			fi
			cp -a ${src_lib} "${D}"$(alt_libdir)/tls/${l} || die "copying nptl ${l}"
			fperms a+rx $(alt_libdir)/tls/${l}
			dosym ${l} $(alt_libdir)/tls/$(scanelf -qSF'%S#F' ${src_lib})

			# then grab the linker script or the symlink ...
			if [[ -L ${D}$(alt_usrlibdir)/${l} ]] ; then
				dosym $(alt_libdir)/tls/${l} $(alt_usrlibdir)/nptl/${l}
			else
				sed \
					-e "s:/${l}:/tls/${l}:g" \
					-e "s:/${l/%.so/_nonshared.a}:/nptl/${l/%.so/_nonshared.a}:g" \
					"${D}"$(alt_usrlibdir)/${l} > "${D}"$(alt_usrlibdir)/nptl/${l}
			fi

			# then grab the static lib ...
			src_lib=${src_lib/%.so/.a}
			[[ ! -e ${src_lib} ]] && src_lib=${src_lib/%.a/_pic.a}
			cp -a ${src_lib} "${D}"$(alt_usrlibdir)/nptl/ || die "copying nptl ${src_lib}"
			src_lib=${src_lib/%.a/_nonshared.a}
			if [[ -e ${src_lib} ]] ; then
				cp -a ${src_lib} "${D}"$(alt_usrlibdir)/nptl/ || die "copying nptl ${src_lib}"
			fi
		done

		# use the nptl linker instead of the linuxthreads one as the linuxthreads
		# one may lack TLS support and that can be really bad for business
		cp -a elf/ld.so "${D}"$(alt_libdir)/$(scanelf -qSF'%S#F' elf/ld.so) || die "copying nptl interp"
	fi

	# We'll take care of the cache ourselves
	rm -f "${D}"/etc/ld.so.cache

	# Some things want this, notably ash.
	dosym libbsd-compat.a $(alt_usrlibdir)/libbsd.a

	# Handle includes for different ABIs
	prep_ml_includes $(alt_headers)

	# When cross-compiling for a non-multilib setup, make sure we have
	# lib and a proper symlink setup
	if is_crosscompile && ! use multilib && ! has_multilib_profile && [[ $(get_libdir) != "lib" ]] ; then
		cd "${D}"$(alt_libdir)/..
		mv $(get_libdir) lib || die
		ln -s lib $(get_libdir) || die
		cd "${D}"$(alt_usrlibdir)/..
		mv $(get_libdir) lib || die
		ln -s lib $(get_libdir) || die
	fi

	#################################################################
	# EVERYTHING AFTER THIS POINT IS FOR NATIVE GLIBC INSTALLS ONLY #
	# Make sure we install some symlink hacks so that when we build
	# a 2nd stage cross-compiler, gcc finds the target system
	# headers correctly.  See gcc/doc/gccinstall.info
	if is_crosscompile ; then
		dosym usr/include /usr/${CTARGET}/sys-include
		return 0
	fi

	# Everything past this point just needs to be done once ...
	is_final_abi || return 0

	# Make sure the non-native interp can be found on multilib systems
	if has_multilib_profile ; then
		case $(tc-arch) in
			amd64)
				[[ ! -e ${D}/lib ]] && dosym $(get_abi_LIBDIR amd64) /lib
				dosym ../$(get_abi_LIBDIR x86)/ld-linux.so.2 /lib/ld-linux.so.2
				;;
			ppc64)
				[[ ! -e ${D}/lib ]] && dosym $(get_abi_LIBDIR ppc64) /lib
				dosym ../$(get_abi_LIBDIR ppc)/ld.so.1 /lib/ld.so.1
				;;
		esac
	fi

	# Files for Debian-style locale updating
	dodir /usr/share/i18n
	sed \
		-e "/^#/d" \
		-e "/SUPPORTED-LOCALES=/d" \
		-e "s: \\\\::g" -e "s:/: :g" \
		"${S}"/localedata/SUPPORTED > "${D}"/usr/share/i18n/SUPPORTED \
		|| die "generating /usr/share/i18n/SUPPORTED failed"
	cd "${WORKDIR}"/extra/locale
	dosbin locale-gen || die
	doman *.[0-8]
	insinto /etc
	doins locale.gen || die

	# Make sure all the ABI's can find the locales and so we only
	# have to generate one set
	local a
	keepdir /usr/$(get_libdir)/locale
	for a in $(get_install_abis) ; do
		if [[ ! -e ${D}/usr/$(get_abi_LIBDIR ${a})/locale ]] ; then
			dosym /usr/$(get_libdir)/locale /usr/$(get_abi_LIBDIR ${a})/locale
		fi
	done

	if ! has noinfo ${FEATURES} && [[ ${GLIBC_INFOPAGE_VERSION} != "none" ]] ; then
		einfo "Installing info pages..."

		make \
			-C "${GBUILDDIR}" \
			PARALLELMFLAGS="${MAKEOPTS}" \
			install_root="${install_root}" \
			info -i || die
	fi

	if [[ ${GLIBC_MANPAGE_VERSION} != "none" ]] ; then
		einfo "Installing man pages..."

		# Install linuxthreads man pages even if nptl is enabled
		cd "${WORKDIR}"/man
		doman *.3thr
	fi

	cd "${S}"

	# Install misc network config files
	insinto /etc
	doins nscd/nscd.conf posix/gai.conf nss/nsswitch.conf || die
	doins "${WORKDIR}"/extra/etc/*.conf || die
	doinitd "${WORKDIR}"/extra/etc/nscd || die

	dodoc BUGS ChangeLog* CONFORMANCE FAQ NEWS NOTES PROJECTS README*

	# Prevent overwriting of the /etc/localtime symlink.  We'll handle the
	# creation of the "factory" symlink in pkg_postinst().
	rm -f "${D}"/etc/localtime
}

toolchain-glibc_headers_install() {
	local GBUILDDIR=${WORKDIR}/build-${ABI}-${CTARGET}-headers
	cd "${GBUILDDIR}"
	make install_root="${D}/usr/${CTARGET}" install-headers || die "install-headers failed"
	# Copy over headers that are not part of install-headers ... these
	# are pretty much taken verbatim from crosstool, see it for more details
	insinto $(alt_headers)/bits
	doins misc/syscall-list.h bits/stdio_lim.h || die "doins include bits"
	insinto $(alt_headers)/gnu
	doins "${S}"/include/gnu/stubs.h || die "doins include gnu"
	# Make sure we install the sys-include symlink so that when
	# we build a 2nd stage cross-compiler, gcc finds the target
	# system headers correctly.  See gcc/doc/gccinstall.info
	dosym usr/include /usr/${CTARGET}/sys-include
}

toolchain-glibc_pkg_postinst() {
	# Mixing nptlonly and -nptlonly glibc can prove dangerous if libpthread
	# isn't removed in unmerge which happens sometimes.  See bug #87671
	if ! is_crosscompile && want_linuxthreads && [[ ${ROOT} == "/" ]] ; then
		for libdir in $(get_all_libdirs) ; do
			for f in "${ROOT}"/${libdir}/libpthread-2.* "${ROOT}"/${libdir}/libpthread-0.6* ; do
				if [[ -f ${f} ]] ; then
					rm -f ${f}
					ldconfig
				fi
			done
		done
	fi

	if ! tc-is-cross-compiler && [[ -x ${ROOT}/usr/sbin/iconvconfig ]] ; then
		# Generate fastloading iconv module configuration file.
		"${ROOT}"/usr/sbin/iconvconfig --prefix="${ROOT}"
	fi

	if [[ ! -e ${ROOT}/lib/ld.so.1 ]] && use ppc64 && ! has_multilib_profile ; then
		## SHOULDN'T THIS BE lib64??
		ln -s ld64.so.1 "${ROOT}"/lib/ld.so.1
	fi

	if ! is_crosscompile && [[ ${ROOT} == "/" ]] ; then
		# Reload init ...
		/sbin/telinit U &> /dev/null

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

	echo
	einfo "Gentoo's glibc no longer includes mdns."
	einfo "If you want mdns, emerge the sys-auth/nss-mdns package."
	echo

	if want_nptl && want_linuxthreads ; then
		einfo "The default behavior of glibc on your system is to use NPTL.  If"
		einfo "you want to use linuxthreads for a particular program, start it"
		einfo "by executing 'LD_ASSUME_KERNEL=${LT_KERNEL_VERSION} <program> [<options>]'"
		echo
	fi
}

### SUPPORT FUNCTIONS ###
# We need to be able to set alternative headers for
# compiling for non-native platform
# Will also become useful for testing kernel-headers without screwing up
# the whole system.
# note: intentionally undocumented.
alt_headers() {
	if [[ -z ${ALT_HEADERS} ]] ; then
		if is_crosscompile ; then
			ALT_HEADERS="/usr/${CTARGET}/usr/include"
		else
			ALT_HEADERS="/usr/include"
		fi
	fi
	echo "${ALT_HEADERS}"
}
alt_build_headers() {
	if [[ -z ${ALT_BUILD_HEADERS} ]] ; then
		ALT_BUILD_HEADERS=$(alt_headers)
		if tc-is-cross-compiler ; then
			ALT_BUILD_HEADERS=${ROOT}$(alt_headers)
			if [[ ! -e ${ALT_BUILD_HEADERS}/linux/version.h ]] ; then
				local header_path=$(echo '#include <linux/version.h>' | $(tc-getCPP ${CTARGET}) ${CFLAGS} 2>&1 | grep -o '[^"]*linux/version.h')
				ALT_BUILD_HEADERS=${header_path%/linux/version.h}
			fi
		fi
	fi
	echo "${ALT_BUILD_HEADERS}"
}

alt_libdir() {
	if is_crosscompile ; then
		echo /usr/${CTARGET}/$(get_libdir)
	else
		echo /$(get_libdir)
	fi
}

alt_usrlibdir() {
	if is_crosscompile ; then
		echo /usr/${CTARGET}/usr/$(get_libdir)
	else
		echo /usr/$(get_libdir)
	fi
}

setup_flags() {
	# Make sure host make.conf doesn't pollute us
	if is_crosscompile || tc-is-cross-compiler ; then
		CHOST=${CTARGET} strip-unsupported-flags
	fi

	# Store our CFLAGS because it's changed depending on which CTARGET
	# we are building when pulling glibc on a multilib profile
	CFLAGS_BASE=${CFLAGS_BASE-${CFLAGS}}
	CFLAGS=${CFLAGS_BASE}
	CXXFLAGS_BASE=${CXXFLAGS_BASE-${CXXFLAGS}}
	CXXFLAGS=${CXXFLAGS_BASE}
	ASFLAGS_BASE=${ASFLAGS_BASE-${ASFLAGS}}
	ASFLAGS=${ASFLAGS_BASE}

	# Over-zealous CFLAGS can often cause problems.  What may work for one
	# person may not work for another.  To avoid a large influx of bugs
	# relating to failed builds, we strip most CFLAGS out to ensure as few
	# problems as possible.
	strip-flags
	strip-unsupported-flags
	filter-flags -m32 -m64 -mabi=*

	unset CBUILD_OPT CTARGET_OPT
	if has_multilib_profile ; then
		CTARGET_OPT=$(get_abi_CTARGET)
		[[ -z ${CTARGET_OPT} ]] && CTARGET_OPT=$(get_abi_CHOST)
	fi

	case $(tc-arch) in
		amd64)
			# Punt this when amd64's 2004.3 is removed
			CFLAGS_x86="-m32"
		;;
		ppc)
			append-flags "-freorder-blocks"
		;;
		sparc)
			# Both sparc and sparc64 can use -fcall-used-g6.  -g7 is bad, though.
			filter-flags "-fcall-used-g7"
			append-flags "-fcall-used-g6"
			filter-flags "-mvis"

			if is_crosscompile || [[ ${PROFILE_ARCH} == "sparc64" ]] || { has_multilib_profile && ! tc-is-cross-compiler; } ; then
				case ${ABI} in
					sparc64)
						filter-flags -Wa,-xarch -Wa,-A

						if is-flag "-mcpu=ultrasparc3"; then
							CTARGET_OPT="sparc64b-unknown-linux-gnu"
							append-flags "-Wa,-xarch=v9b"
							export ASFLAGS="${ASFLAGS} -Wa,-xarch=v9b"
						else
							CTARGET_OPT="sparc64-unknown-linux-gnu"
							append-flags "-Wa,-xarch=v9a"
							export ASFLAGS="${ASFLAGS} -Wa,-xarch=v9a"
						fi
					;;
					*)
						if is-flag "-mcpu=ultrasparc3"; then
							CTARGET_OPT="sparcv9b-unknown-linux-gnu"
						else
							CTARGET_OPT="sparcv9-unknown-linux-gnu"
						fi
					;;
				esac
			else
				if is-flag "-mcpu=ultrasparc3"; then
					CTARGET_OPT="sparcv9b-unknown-linux-gnu"
				elif { is_crosscompile && want_nptl; } || is-flag "-mcpu=ultrasparc2" || is-flag "-mcpu=ultrasparc"; then
					CTARGET_OPT="sparcv9-unknown-linux-gnu"
				fi
			fi
		;;
	esac

	if [[ -n ${CTARGET_OPT} && ${CBUILD} == ${CHOST} ]] && ! is_crosscompile; then
		CBUILD_OPT=${CTARGET_OPT}
	fi

	# Lock glibc at -O2 -- linuxthreads needs it and we want to be
	# conservative here.  -fno-strict-aliasing is to work around #155906
	filter-flags -O?
	append-flags -O2 -fno-strict-aliasing

	# building glibc with SSP is fraught with difficulty, especially
	# due to __stack_chk_fail_local which would mean significant changes
	# to the glibc build process. See bug #94325
	filter-flags -fstack-protector

	if use hardened && gcc-specs-pie ; then
		# Force PIC macro definition for all compilations since they're all
		# either -fPIC or -fPIE with the default-PIE compiler.
		append-cppflags -DPIC
	else
		# Don't build -fPIE without the default-PIE compiler and the
		# hardened-pie patch
		filter-flags -fPIE
	fi
}

check_kheader_version() {
	local version=$(
		printf '#include <linux/version.h>\nLINUX_VERSION_CODE\n' | \
		$(tc-getCPP ${CTARGET}) -I "$(alt_build_headers)" | \
		tail -n 1
	)
	[[ ${version} -ge "$1" ]]
}

check_nptl_support() {
	local min_kernel_version=$(KV_to_int "${NPTL_KERNEL_VERSION}")

	echo

	ebegin "Checking gcc for __thread support"
	if ! eend $(want__thread ; echo $?) ; then
		echo
		eerror "Could not find a gcc that supports the __thread directive!"
		eerror "Please update your binutils/gcc and try again."
		die "No __thread support in gcc!"
	fi

	if ! is_crosscompile && ! tc-is-cross-compiler ; then
		# Building fails on an non-supporting kernel
		ebegin "Checking kernel version (>=${NPTL_KERNEL_VERSION})"
		if ! eend $([[ $(get_KV) -ge ${min_kernel_version} ]] ; echo $?) ; then
			echo
			eerror "You need a kernel of at least version ${NPTL_KERNEL_VERSION}"
			eerror "for NPTL support!"
			die "Kernel version too low!"
		fi
	fi

	# Building fails with too low linux-headers
	ebegin "Checking linux-headers version (>=${NPTL_KERNEL_VERSION})"
	if ! eend $(check_kheader_version "${min_kernel_version}" ; echo $?) ; then
		echo
		eerror "You need linux-headers of at least version ${NPTL_KERNEL_VERSION}"
		eerror "for NPTL support!"
		die "linux-headers version too low!"
	fi

	echo
}

want_nptl() {
	want_tls || return 1
	use nptl || return 1

	# Only list the arches that cannot do NPTL
	case $(tc-arch) in
		m68k) return 1;;
		sparc)
			# >= v9 is needed for nptl.
			[[ ${PROFILE_ARCH} == "sparc" ]] && return 1
		;;
	esac

	return 0
}

want_linuxthreads() {
	! use nptlonly && return 0
	want_nptl || return 0
	return 1
}

want_tls() {
	# Archs that can use TLS (Thread Local Storage)
	case $(tc-arch) in
		sparc)
			# 2.3.6 should have tls support on sparc64
			# when using newer binutils
			case ${CTARGET/-*} in
				sparc64*) return 1 ;;
				*) return 0 ;;
			esac
		;;
		x86)
			# requires i486 or better #106556
			[[ ${CTARGET} == i[4567]86* ]] && return 0
			return 1
		;;
	esac

	return 0
}

want__thread() {
	want_tls || return 1

	# For some reason --with-tls --with__thread is causing segfaults on sparc32.
	[[ ${PROFILE_ARCH} == "sparc" ]] && return 1

	[[ -n ${WANT__THREAD} ]] && return ${WANT__THREAD}

	echo 'extern __thread int i;' > "${T}"/test-__thread.c
	$(tc-getCC ${CTARGET}) -c "${T}"/test-__thread.c -o "${T}"/test-__thread.o &> /dev/null
	WANT__THREAD=$?
	rm -f "${T}"/test-__thread.[co]

	return ${WANT__THREAD}
}

glibc_do_configure() {
	local myconf

	# set addons
	pushd "${S}" > /dev/null
	local ADDONS=$(echo */configure | sed \
		-e 's:/configure::g' \
		-e 's:\(linuxthreads\|nptl\|rtkaio\|glibc-compat\)\( \|$\)::g' \
		-e 's: \+$::' \
		-e 's! !,!g' \
		-e 's!^!,!' \
		-e '/^,\*$/d')
	popd > /dev/null

	use nls || myconf="${myconf} --disable-nls"
	myconf="${myconf} $(use_enable hardened stackguard-randomization)"
	if [[ $(<"${T}"/.ssp.compat) == "yes" ]] ; then
		myconf="${myconf} --enable-old-ssp-compat"
	else
		myconf="${myconf} --disable-old-ssp-compat"
	fi

	use glibc-omitfp && myconf="${myconf} --enable-omitfp"

	[[ ${CTARGET//_/-} == *-softfloat-* ]] && myconf="${myconf} --without-fp"

	if [[ $1 == "linuxthreads" ]] ; then
		if want_tls ; then
			myconf="${myconf} --with-tls"

			if ! want__thread || use glibc-compat20 || [[ ${LT_KERNEL_VERSION} == 2.[02].* ]] ; then
				myconf="${myconf} --without-__thread"
			else
				myconf="${myconf} --with-__thread"
			fi
		else
			myconf="${myconf} --without-tls --without-__thread"
		fi

		myconf="${myconf} --disable-sanity-checks"
		myconf="${myconf} --enable-add-ons=ports,linuxthreads${ADDONS}"
		myconf="${myconf} --enable-kernel=${LT_KERNEL_VERSION}"
	elif [[ $1 == "nptl" ]] ; then
		myconf="${myconf} --with-tls --with-__thread"
		myconf="${myconf} --enable-add-ons=ports,nptl${ADDONS}"
		myconf="${myconf} --enable-kernel=${NPTL_KERNEL_VERSION}"
	else
		die "invalid pthread option"
	fi

	# Since SELinux support is only required for nscd, only enable it if:
	# 1. USE selinux
	# 2. ! USE build
	# 3. only for the primary ABI on multilib systems
	if use selinux && ! use build ; then
		if use multilib || has_multilib_profile ; then
			if is_final_abi ; then
				myconf="${myconf} --with-selinux"
			else
				myconf="${myconf} --without-selinux"
			fi
		else
			myconf="${myconf} --with-selinux"
		fi
	else
		myconf="${myconf} --without-selinux"
	fi

	myconf="${myconf}
		--without-cvs
		--enable-bind-now
		--build=${CBUILD_OPT:-${CBUILD}}
		--host=${CTARGET_OPT:-${CTARGET}}
		$(use_enable profile)
		--without-gd
		--with-headers=$(alt_build_headers)
		--prefix=/usr
		--libdir=/usr/$(get_libdir)
		--mandir=/usr/share/man
		--infodir=/usr/share/info
		--libexecdir=/usr/$(get_libdir)/misc/glibc
		${EXTRA_ECONF}"

	# There is no configure option for this and we need to export it
	# since the glibc build will re-run configure on itself
	export libc_cv_slibdir=/$(get_libdir)

	has_version app-admin/eselect-compiler || export CC=$(tc-getCC ${CTARGET})

	local GBUILDDIR=${WORKDIR}/build-${ABI}-${CTARGET}-$1
	mkdir -p "${GBUILDDIR}"
	cd "${GBUILDDIR}"
	einfo "Configuring GLIBC for $1 with: ${myconf// /\n\t\t}"
	"${S}"/configure ${myconf} || die "failed to configure glibc"
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
		addwrite ${ROOT}/
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
		addwrite ${ROOT}/usr
		rm ${ROOT}/usr/lib64
		mv ${ROOT}/usr/lib ${ROOT}/usr/lib64
		ln -s lib64 ${ROOT}/usr/lib
		einfo "fixed broken lib64/lib symlink in ${ROOT}/usr"
	fi
	if [ -L ${ROOT}/usr/X11R6/lib64 ] ; then
		addwrite ${ROOT}/usr/X11R6
		rm ${ROOT}/usr/X11R6/lib64
		mv ${ROOT}/usr/X11R6/lib ${ROOT}/usr/X11R6/lib64
		ln -s lib64 ${ROOT}/usr/X11R6/lib
		einfo "fixed broken lib64/lib symlink in ${ROOT}/usr/X11R6"
	fi
}

use_multilib() {
	case ${CTARGET} in
		sparc64*|mips64*|x86_64*|powerpc64*|s390x*)
			has_multilib_profile || use multilib ;;
		*)  false ;;
	esac
}

# Setup toolchain variables that would be defined in the profiles for these archs.
setup_env() {
	# These should not be set, else the zoneinfo do not always get installed ...
	unset LANGUAGE LANG LC_ALL
	# silly users
	unset LD_RUN_PATH

	if is_crosscompile || tc-is-cross-compiler ; then
		multilib_env ${CTARGET}
		if ! use multilib ; then
			MULTILIB_ABIS=${DEFAULT_ABI}
		else
			MULTILIB_ABIS=${MULTILIB_ABIS:-${DEFAULT_ABI}}
		fi

		# If the user has CFLAGS_<CTARGET> in their make.conf, use that,
		# and fall back on CFLAGS.
		local VAR=CFLAGS_${CTARGET//[-.]/_}
		CFLAGS=${!VAR-${CFLAGS}}
	fi

	setup_flags

	export ABI=${ABI:-${DEFAULT_ABI:-default}}

	if is_crosscompile || tc-is-cross-compiler ; then
		local VAR=CFLAGS_${ABI}
		# We need to export CFLAGS with abi information in them because
		# glibc's configure script checks CFLAGS for some targets (like mips)
		export CFLAGS="${!VAR} ${CFLAGS}"
	fi
}

### /ECLASS PUNTAGE ###

if is_crosscompile ; then
	SLOT="${CTARGET}-2.2"
else
	SLOT="2.2"
fi

# we'll handle stripping ourself #46186
RESTRICT="strip"
EMULTILIB_PKG="true"

# General: We need a new-enough binutils for as-needed
# arch: we need to make sure our binutils/gcc supports TLS
DEPEND=">=sys-devel/gcc-3.4.4
	arm? ( >=sys-devel/binutils-2.16.90 >=sys-devel/gcc-4.1.0 )
	ppc? ( >=sys-devel/gcc-4.1.0 )
	ppc64? ( >=sys-devel/gcc-4.1.0 )
	nptl? ( || ( >=sys-kernel/mips-headers-${NPTL_KERNEL_VERSION} >=sys-kernel/linux-headers-${NPTL_KERNEL_VERSION} ) )
	>=sys-devel/binutils-2.15.94
	>=sys-devel/gcc-config-1.3.12
	>=app-misc/pax-utils-0.1.10
	virtual/os-headers
	nls? ( sys-devel/gettext )
	>=sys-apps/portage-2.1.2
	selinux? ( !build? ( sys-libs/libselinux ) )"
RDEPEND="nls? ( sys-devel/gettext )
	selinux? ( !build? ( sys-libs/libselinux ) )"

if [[ ${CATEGORY/cross-} != ${CATEGORY} ]] ; then
	DEPEND="${DEPEND} !crosscompile_opts_headers-only? ( ${CATEGORY}/gcc )"

	if [[ ${CATEGORY} == *-linux* ]] ; then
		if [[ ${CATEGORY} == cross-mips* ]] ; then
			DEPEND="${DEPEND} >=${CATEGORY}/mips-headers-2.6.10"
		else
			DEPEND="${DEPEND} ${CATEGORY}/linux-headers"
		fi
	fi
else
	DEPEND="${DEPEND} >=sys-libs/timezone-data-2007c"
	RDEPEND="${RDEPEND} sys-libs/timezone-data"
fi

pkg_setup() {
	# prevent native builds from downgrading ... maybe update to allow people
	# to change between diff -r versions ? (2.3.6-r4 -> 2.3.6-r2)
	if ! is_crosscompile && ! tc-is-cross-compiler ; then
		if has_version '>'${CATEGORY}/${PF} ; then
			eerror "Sanity check to keep you from breaking your system:"
			eerror " Downgrading glibc is not supported and a sure way to destruction"
			die "aborting to save your system"
		fi
	fi

	if [[ ${CTARGET} == i386-* ]] ; then
		eerror "i386 CHOSTs are no longer supported."
		eerror "Chances are you don't actually want/need i386."
		eerror "Please read http://www.gentoo.org/doc/en/change-chost.xml"
		die "please fix your CHOST"
	fi

	if use nptlonly && ! use nptl ; then
		eerror "If you want nptlonly, add nptl to your USE too ;p"
		die "nptlonly without nptl"
	fi

	if [[ -e /proc/xen ]] && [[ $(tc-arch) == "x86" ]] && ! is-flag -mno-tls-direct-seg-refs ; then
		ewarn "You are using Xen but don't have -mno-tls-direct-seg-refs in your CFLAGS."
		ewarn "This will result in a 50% performance penalty, which is probably not what you want."
	fi

	if ! type -p scanelf > /dev/null ; then
		eerror "You do not have pax-utils installed."
		die "install pax-utils"
	fi

	use hardened && ! gcc-specs-pie && \
		ewarn "PIE hardening not applied, as your compiler doesn't default to PIE"
}

src_unpack() {
	setup_env

	toolchain-glibc_src_unpack

	# Backwards SSP support
	cd "${S}"
# For now, we force everyone to have the extra symbols
#	einfon "Scanning system for __guard to see if we need SSP compat ... "
#	if [[ -n $(scanelf -qyls__guard -F'#s%F' | grep -v '^/lib.*/libc-2.*.so$') ]] ; then
		echo "yes" > "${T}"/.ssp.compat
#	else
#		# ok, a quick scan didnt find it, so lets do a deep scan ...
#		if [[ -n $(scanelf -qyRlps__guard -F'#s%F' | grep -v '^/lib.*/libc-2.*.so$') ]] ; then
#			echo "yes" > "${T}"/.ssp.compat
#		else
#			echo "no" > "${T}"/.ssp.compat
#		fi
#	fi
#	cat "${T}"/.ssp.compat

	# Glibc is stupid sometimes, and doesn't realize that with a
	# static C-Only gcc, -lgcc_eh doesn't exist.
	# http://sources.redhat.com/ml/libc-alpha/2003-09/msg00100.html
	# http://sourceware.org/ml/libc-alpha/2005-02/msg00042.html
	echo 'int main(){}' > "${T}"/gcc_eh_test.c
	if ! $(tc-getCC ${CTARGET}) "${T}"/gcc_eh_test.c -lgcc_eh 2>/dev/null ; then
		sed -i -e 's:-lgcc_eh::' Makeconfig || die "sed gcc_eh"
	fi

	cd "${WORKDIR}"
	find . -type f '(' -size 0 -o -name "*.orig" ')' -exec rm -f {} \;
	find . -name configure -exec touch {} \;

	# Fix permissions on some of the scripts
	chmod u+x "${S}"/scripts/*.sh
}

src_compile() {
	setup_env

	if [[ -z ${OABI} ]] ; then
		local abilist=""
		if has_multilib_profile ; then
			abilist=$(get_install_abis)
			einfo "Building multilib glibc for ABIs: ${abilist}"
		elif is_crosscompile || tc-is-cross-compiler ; then
			abilist=${DEFAULT_ABI}
		fi
		if [[ -n ${abilist} ]] ; then
			OABI=${ABI}
			for ABI in ${abilist} ; do
				export ABI
				src_compile
			done
			ABI=${OABI}
			unset OABI
			return 0
		fi
	fi

	if just_headers ; then
		toolchain-glibc_headers_compile
	else
		toolchain-glibc_src_compile
	fi
}

src_test() {
	local ret=0

	setup_env

	if [[ -z ${OABI} ]] && has_multilib_profile ; then
		OABI=${ABI}
		einfo "Testing multilib glibc for ABIs: $(get_install_abis)"
		for ABI in $(get_install_abis) ; do
			export ABI
			einfo "   Testing ${ABI} glibc"
			src_test
			((ret+=$?))
		done
		ABI=${OABI}
		unset OABI
		[[ ${ret} -ne 0 ]] \
			&& die "tests failed" \
			|| return 0
	fi

	want_linuxthreads && toolchain-glibc_src_test linuxthreads ; ((ret+=$?))
	want_nptl && toolchain-glibc_src_test nptl ; ((ret+=$?))
	return ${ret}
}

src_strip() {
	# Now, strip everything but the thread libs #46186, as well as the dynamic
	# linker, else we cannot set breakpoints in shared libraries due to bugs in
	# gdb.  Also want to grab stuff in tls subdir.  whee.
	env \
		-uRESTRICT \
		CHOST=${CTARGET} \
		STRIP_MASK="/*/{,tls/}{ld-,lib{pthread,thread_db}}*" \
		prepallstrip
}

src_install() {
	setup_env

	if [[ -z ${OABI} ]] ; then
		local abilist=""
		if has_multilib_profile ; then
			abilist=$(get_install_abis)
			einfo "Installing multilib glibc for ABIs: ${abilist}"
		elif is_crosscompile || tc-is-cross-compiler ; then
			abilist=${DEFAULT_ABI}
		fi
		if [[ -n ${abilist} ]] ; then
			OABI=${ABI}
			for ABI in ${abilist} ; do
				export ABI
				src_install
			done
			ABI=${OABI}
			unset OABI
			src_strip
			return 0
		fi
	fi

	if just_headers ; then
		toolchain-glibc_headers_install
	else
		toolchain-glibc_src_install
	fi
	[[ -z ${OABI} ]] && src_strip
}

pkg_preinst() {
	toolchain-glibc_pkg_preinst
}

pkg_postinst() {
	toolchain-glibc_pkg_postinst
}
