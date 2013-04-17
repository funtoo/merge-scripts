# Distributed under the terms of the GNU General Public License v2

PATCH_VER="1.1"
UCLIBC_VER="1.0"

# Hardened gcc 4 stuff
PIE_VER="0.5.5"
SPECS_VER="0.2.0"
SPECS_GCC_VER="4.4.3"
# arch/libc configurations known to be stable with {PIE,SSP}-by-default
PIE_GLIBC_STABLE="x86 amd64 ppc ppc64 arm ia64"
PIE_UCLIBC_STABLE="x86 arm amd64 ppc ppc64"
SSP_STABLE="amd64 x86 ppc ppc64 arm"
# uclibc need tls and nptl support for SSP support
# uclibc need to be >= 0.9.33
SSP_UCLIBC_STABLE="x86 amd64 ppc ppc64 arm"
#end Hardened stuff

inherit toolchain

DESCRIPTION="The GNU Compiler Collection"

LICENSE="GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.3+"

KEYWORDS=""

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.8 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

src_unpack() {
	if has_version '<sys-libs/glibc-2.12' ; then
		ewarn "Your host glibc is too old; disabling automatic fortify."
		ewarn "Please rebuild gcc after upgrading to >=glibc-2.12 #362315"
		EPATCH_EXCLUDE+=" 10_all_default-fortify-source.patch"
	fi

	# drop the x32 stuff once 4.7 goes stable
#	if [[ ${CTARGET} != x86_64* ]] || ! has x32 $(get_all_abis TARGET) ; then
#		EPATCH_EXCLUDE+=" 90_all_gcc-4.7-x32.patch"
#	fi

	toolchain_src_unpack

	use vanilla && return 0

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${FILESDIR}"/gcc-spec-env.patch
}

pkg_setup() {
	toolchain_pkg_setup

	ewarn
	ewarn "LTO support is still experimental and unstable.  Any bug reports"
	ewarn "about LTO that do not include an upstream patch will be closed as"
	ewarn "invalid."
	ewarn
}

pkg_postinst() {
	elog
	elog "Packages failing to build with GCC 4.8 are tracked at"
	elog "https://bugs.gentoo.org/461954"
	elog
}
