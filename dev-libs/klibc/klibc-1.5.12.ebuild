# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/klibc/klibc-1.5.12.ebuild,v 1.2 2009/09/25 10:34:14 flameeyes Exp $

# Robin H. Johnson <robbat2@gentoo.org>, 12 Nov 2007:
# This still needs major work.
# But it is significently better than the previous version.
# In that it will now build on biarch systems, such as ppc64-32ul.

# NOTES:
# ======
# We need to bring in the kernel sources seperately
# Because they have to be configured in a way that differs from the copy in
# /usr/src/. The sys-kernel/linux-headers are too stripped down to use
# unfortunetly.
# This will be able to go away once the klibc author updates his code
# to build again the headers provided by the kernel's 'headers_install' target.

inherit eutils multilib toolchain-funcs

DESCRIPTION="A minimal libc subset for use with initramfs."
HOMEPAGE="http://www.zytor.com/mailman/listinfo/klibc"
KV_MAJOR="2" KV_MINOR="6" KV_SUB="23"
OKV="${KV_MAJOR}.${KV_MINOR}.${KV_SUB}"
PKV="${KV_MAJOR}.${KV_MINOR}.$((${KV_SUB}+1))-rc7"
PATCH_URI="mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/patch-${PKV}.bz2"
KERNEL_URI="mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/testing/linux-${OKV}.tar.bz2"
SRC_URI="
	mirror://kernel/linux/libs/klibc/${P}.tar.bz2
	mirror://kernel/linux/libs/klibc/Testing/${P}.tar.bz2
	${PATCH_URI}
	${KERNEL_URI}"

LICENSE="|| ( GPL-2 LGPL-2 )"
KEYWORDS="~amd64 -mips ~ppc ~sparc ~x86"
SLOT="0"
IUSE="debug n32"

DEPEND="dev-lang/perl"
RDEPEND="${DEPEND}"

KS="${WORKDIR}/linux-${OKV}"

# Klibc has no PT_GNU_STACK support, so scanning for execstacks is moot
QA_EXECSTACK="*"
# Do not strip
RESTRICT="strip"

src_unpack() {
	unpack linux-${OKV}.tar.bz2 ${P}.tar.bz2
	EPATCH_OPTS="-d ${KS} -p1" epatch "${DISTDIR}"/patch-${PKV}.bz2
	cd "${S}"

	# Symlink /usr/src/linux to ${S}/linux
	ln -snf "${KS}" linux
	#ln -snf "/usr" linux

	# Build interp.o with EXTRA_KLIBCAFLAGS (.S source)
	epatch "${FILESDIR}"/${PN}-1.4.11-interp-flags.patch

	# Fixes for sparc and ppc
	epatch "${FILESDIR}"/${PN}-1.5-sigaction.patch

	# Fix the asm-ppc vs. asm-powerpc issue, bug #196521
	epatch "${FILESDIR}"/${PN}-1.5.11-klibcasmarch.patch

	# Fix usage of -s, bug #201006
	epatch "${FILESDIR}"/klibc-1.5.7-strip-fix-dash-s.patch

	# bug 229525, usr/include/arch/x86_64/sys/io.h has undefined variables
	epatch "${FILESDIR}"/${PN}-1.5.11-x86_64-io.h-return.diff
}

# For a given Gentoo ARCH,
# specify the kernel defconfig most relevant
kernel_defconfig() {
	a="${1:${ARCH}}"
	# most, but not all arches have a sanely named defconfig
	case ${a} in
		ppc64) echo ppc64_defconfig ;;
		ppc) echo pmac32_defconfig ;;
		arm*|sh*) die "TODO: Your arch is not supported by the klibc ebuild. Please suggest a defconfig in a bug." ;;
		*) echo defconfig ;;
	esac
}

# klibc has it's own ideas of arches
# They reflect userspace strictly.
# This functions maps from a Gentoo ARCH, to an arch that klibc expects
# Look at klibc-${S}/usr/klibc/arch for a list of these arches
klibc_arch() {
	a="${1:${ARCH}}"
	case ${a} in
		amd64) echo x86_64;;
		mips) die 'TODO: Use the $ABI' ;;
		x86) echo i386;;
		*) echo ${a} ;;
	esac
}

kernel_asm_arch() {
	a="${1:${ARCH}}"
	case ${a} in
		# Merged arches
		x86|amd64) echo x86 ;;
		ppc*) echo powerpc ;;
		# Non-merged
		alpha|arm|ia64|m68k|mips|sh|sparc*) echo ${1} ;;
		*) die "TODO: Update the code for your asm-ARCH symlink" ;;
	esac
}

src_compile() {
	local myargs
	local myARCH="${ARCH}" myABI="${ABI}"
	# TODO: For cross-compiling
	# You should set ARCH and ABI here
	CC="$(tc-getCC)"
	HOSTCC="$(tc-getBUILD_CC)"
	KLIBCARCH="$(klibc_arch ${ARCH})"
	KLIBCASMARCH="$(kernel_asm_arch ${ARCH})"
	libdir="$(get_libdir)"
	# This should be the defconfig corresponding to your userspace!
	# NOT your kernel. PPC64-32ul would choose 'ppc' for example.
	defconfig=$(kernel_defconfig ${ARCH})
	unset ABI ARCH # Unset these, because they interfere
	unset KBUILD_OUTPUT # we are using a private copy

	cd "${KS}"
	emake ${defconfig} || die "No defconfig"
	emake prepare || die "Failed to prepare kernel sources for header usage"

	cd "${S}"

	use debug && myargs="${myargs} V=1"

	emake \
		EXTRA_KLIBCAFLAGS="-Wa,--noexecstack" \
		EXTRA_KLIBCLDFLAGS="-z,noexecstack" \
		HOSTCC="${HOSTCC}" CC="${CC}" \
		INSTALLDIR="/usr/${libdir}/klibc" \
		KLIBCARCH=${KLIBCARCH} \
		KLIBCASMARCH=${KLIBCASMARCH} \
		SHLIBDIR="/${libdir}" \
		libdir="/usr/${libdir}" \
		mandir="/usr/share/man" \
		${myargs} || die "Compile failed!"

		#SHLIBDIR="/${libdir}" \

	ARCH="${myARCH}" ABI="${myABI}"
}

src_install() {
	local myargs
	local myARCH="${ARCH}" myABI="${ABI}"
	# TODO: For cross-compiling
	# You should set ARCH and ABI here
	CC="$(tc-getCC)"
	HOSTCC="$(tc-getBUILD_CC)"
	KLIBCARCH="$(klibc_arch ${ARCH})"
	KLIBCASMARCH="$(kernel_asm_arch ${ARCH})"
	libdir="$(get_libdir)"
	# This should be the defconfig corresponding to your userspace!
	# NOT your kernel. PPC64-32ul would choose 'ppc' for example.
	defconfig=$(kernel_defconfig ${ARCH})

	use debug && myargs="${myargs} V=1"

	local klibc_prefix
	if tc-is-cross-compiler ; then
		klibc_prefix=$("${S}/klcc/${KLIBCARCH}-klcc" -print-klibc-prefix)
	else
		klibc_prefix=$("${S}/klcc/klcc" -print-klibc-prefix)
	fi

	unset ABI ARCH # Unset these, because they interfere
	unset KBUILD_OUTPUT # we are using a private copy

	emake \
		EXTRA_KLIBCAFLAGS="-Wa,--noexecstack" \
		EXTRA_KLIBCLDFLAGS="-z,noexecstack" \
		HOSTCC="${HOSTCC}" CC="${CC}" \
		INSTALLDIR="/usr/${libdir}/klibc" \
		INSTALLROOT="${D}" \
		KLIBCARCH=${KLIBCARCH} \
		KLIBCASMARCH=${KLIBCASMARCH} \
		SHLIBDIR="/${libdir}" \
		libdir="/usr/${libdir}" \
		mandir="/usr/share/man" \
		${myargs} \
		install || die "Install failed!"

		#SHLIBDIR="/${libdir}" \

	# klibc doesn't support prelinking, so we need to mask it
	cat > "${T}/70klibc" <<-EOF
		PRELINK_PATH_MASK="/usr/${libdir}/klibc"
	EOF

	doenvd "${T}"/70klibc

	# Fix the permissions (bug #178053) on /usr/${libdir}/klibc/include
	# Actually I have no idea, why the includes have those weird-ass permissions
	# on a particular system, might be due to inherited permissions from parent
	# directory
	find "${D}"/usr/${libdir}/klibc/include | xargs chmod o+rX

	# Hardlinks becoming copies
	for x in gunzip zcat ; do
		rm -f "${D}/${klibc_prefix}/bin/${x}"
		dosym gzip "${klibc_prefix}/bin/${x}"
	done

	# Restore now, so we can use the tc- functions
	ARCH="${myARCH}" ABI="${myABI}"
	if ! tc-is-cross-compiler ; then
		cd "${S}"
		insinto /usr/share/aclocal
		doins contrib/klibc.m4

		dodoc README usr/klibc/CAVEATS usr/klibc/README
		newdoc usr/klibc/arch/README README.klibc.arch
		docinto dash; newdoc usr/dash/README.klibc README
		docinto gzip; dodoc usr/gzip/README
	fi

	# Fix up the symlink
	# Mainly for merged arches
	linkname="${D}/usr/${libdir}/klibc/include/asm"
	if [ -L "${linkname}" ] && [ ! -e "${linkname}" ] ; then
		ln -snf asm-${KLIBCASMARCH} "${linkname}"
	fi
}
