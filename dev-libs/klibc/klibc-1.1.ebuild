# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/klibc/klibc-1.1.ebuild,v 1.4 2007/07/02 14:54:32 peper Exp $

inherit eutils linux-mod

export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY/cross-} != ${CATEGORY} ]] ; then
		export CTARGET=${CATEGORY/cross-}
	fi
fi

DESCRIPTION="A minimal libc subset for use with initramfs."
HOMEPAGE="http://www.zytor.com/mailman/listinfo/klibc"
SRC_URI="ftp://ftp.kernel.org/pub/linux/libs/klibc/${P}.tar.bz2
	ftp://ftp.kernel.org/pub/linux/libs/klibc/Stable/${P}.tar.bz2
	ftp://ftp.kernel.org/pub/linux/libs/klibc/Testing/${P}.tar.bz2"
LICENSE="|| ( GPL-2 LGPL-2 )"
KEYWORDS="~amd64 mips ~ppc ~x86"
IUSE=""
RESTRICT="strip"

DEPEND="dev-lang/perl
	virtual/linux-sources"
RDEPEND="dev-lang/perl"

if [[ ${CTARGET} != ${CHOST} ]] ; then
	SLOT="${CTARGET}"
else
	SLOT="0"
fi

is_cross() { [[ ${CHOST} != ${CTARGET} ]] ; }

guess_arch() {
	local x
	local host=$(echo "${CTARGET%%-*}" | sed -e 's/i.86/i386/' \
	                                         -e 's/sun4u/sparc64/' \
	                                         -e 's/arm.*/arm/' \
	                                         -e 's/sa110/arm/' \
	                                         -e 's/powerpc/ppc/')

	# Sort reverse so that we will get ppc64 before ppc, etc
	for x in $(ls -1 "${S}/include/arch/" | sort -r) ; do
		if [[ ${host} == "${x}" ]] ; then
			echo "${x}"
			return 0
		fi
	done

	return 1
}

pkg_setup() {
	# Make sure kernel sources are OK
	# (Override for linux-mod eclass)
	check_kernel_built
}

src_unpack() {
	unpack ${A}

	if [[ ! -d /usr/${CTARGET} ]] ; then
		echo
		eerror "It does not look like your cross-compiler is setup properly!"
		die "It does not look like your cross-compiler is setup properly!"
	fi

	if ! guess_arch &>/dev/null ; then
		echo
		eerror "Could not guess klibc's ARCH from your CTARGET!"
		die "Could not guess klibc's ARCH from your CTARGET!"
	fi

	kernel_arch=$(readlink "${KV_OUT_DIR}/include/asm" | sed -e 's:asm-::')
	if [[ ${kernel_arch} != $(guess_arch) ]] ; then
		echo
		eerror "Your kernel sources are not configured for your chosen arch!"
		eerror "(KERNEL_ARCH=\"${kernel_arch}\", ARCH=\"$(guess_arch)\")"
		die "Your kernel sources are not configured for your chosen arch!"
	fi

	cd ${S}

	# Add our linux source tree symlink
	ln -snf ${KV_DIR} linux

	# set the build directory
	echo "KRNLOBJ = ${KV_OUT_DIR}" >> MCONFIG

	# We do not want all the nice prelink warnings
	# NOTE: for amd64, we might change below to '/usr/$(get_libdir)/klibc',
	#       but I do not do it right now, as the build system do not support
	#       the lib64 yet ....
	cat > "${S}/70klibc" <<-EOF
		PRELINK_PATH_MASK="/usr/lib/klibc"
	EOF

	# klibc detects mips64 systems as having 64bit userland
	# Force them to 32bit userlands instead
	epatch ${FILESDIR}/${P}-mips32.patch
}

src_compile() {
	if is_cross ; then
		einfo "ARCH = \"$(guess_arch)\""
		einfo "CROSS = \"${CTARGET}-\""
		emake ARCH=$(guess_arch) \
			CROSS="${CTARGET}-" || die "Compile failed!"
	else
		env -u ARCH \
		emake || die "Compile failed!"
	fi
}

src_install() {
	local klibc_prefix

	if is_cross ; then
		make INSTALLROOT=${D} \
			ARCH=$(guess_arch) \
			CROSS="${CTARGET}-" \
			install || die "Install failed!"

		klibc_prefix=$("${S}/${CTARGET}-klcc" -print-klibc-bindir)
	else
		env -u ARCH \
		make INSTALLROOT=${D} install || die "Install failed!"

		klibc_prefix=$("${S}/klcc" -print-klibc-bindir)
	fi

	# Hardlinks becoming copies
	dosym gzip "${klibc_prefix}/gunzip"
	dosym gzip "${klibc_prefix}/zcat"

	if ! is_cross ; then
		insinto /usr/share/aclocal
		doins ${FILESDIR}/klibc.m4

		doenvd ${S}/70klibc

		dodoc ${S}/README ${S}/klibc/{LICENSE,CAVEATS}
		newdoc ${S}/klibc/README README.klibc
		newdoc ${S}/klibc/arch/README README.klibc.arch
		docinto ash; newdoc ${S}/ash/README.klibc README
		docinto gzip; dodoc ${S}/gzip/{COPYING,README}
		docinto ipconfig; dodoc ${S}/ipconfig/README
		docinto kinit; dodoc ${S}/kinit/README
	fi
}

pkg_postinst() {
	# Override for linux-mod eclass
	return 0
}
