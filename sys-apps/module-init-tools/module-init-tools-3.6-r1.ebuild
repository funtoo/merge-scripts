# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/module-init-tools/module-init-tools-3.6-r1.ebuild,v 1.1 2009/02/16 08:29:25 vapier Exp $

inherit flag-o-matic eutils toolchain-funcs fixheadtails

MODUTILS_PV="2.4.27"

MY_P="${P/_pre/-pre}"
DESCRIPTION="tools for managing linux kernel modules"
HOMEPAGE="http://kerneltools.org/"
SRC_URI="mirror://kernel/linux/utils/kernel/module-init-tools/${MY_P}.tar.bz2
	old-linux? ( mirror://kernel/linux/utils/kernel/modutils/v2.4/modutils-${MODUTILS_PV}.tar.bz2 )
	mirror://gentoo/${MY_P}-man.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE="old-linux"
# The test code runs `make clean && configure` and screws up src_compile()
RESTRICT="test"

DEPEND="sys-libs/zlib
	>=sys-apps/baselayout-1.12.7-r2
	!virtual/modutils"
PROVIDE="virtual/modutils"

S=${WORKDIR}/${MY_P}

src_unpack() {
	unpack ${A}

	# Patches for old modutils
	if use old-linux ; then
		cd "${WORKDIR}"/modutils-${MODUTILS_PV}
		epatch "${FILESDIR}"/modutils-2.4.27-alias.patch
		epatch "${FILESDIR}"/modutils-2.4.27-gcc.patch
		epatch "${FILESDIR}"/modutils-2.4.27-flex.patch
		epatch "${FILESDIR}"/modutils-2.4.27-no-nested-function.patch
		epatch "${FILESDIR}"/modutils-2.4.27-hppa.patch
		epatch "${FILESDIR}"/modutils-2.4.27-build.patch #154281
	fi

	# Fixes for new module-init-tools
	cd "${S}"
	ht_fix_file tests/test-depmod/10badcommand.sh
	# Test fails due since it needs to write to /lib/modules so disable it
	rm -f tests/test-depmod/01backcompat.sh

	# Fix bug 49926: This patch allows generate-modprobe.conf to
	# accept the --assume-kernel=x.x.x option for generating livecds.
	# This is a companion to a patch in baselayout-1.9.0 which allows
	# the same flag to modules-update.
	epatch "${FILESDIR}"/${PN}-3.1_generate-modprobe-assume-kernel.patch

	# Abort if we fail to run modprobe, bug #68689
	epatch "${FILESDIR}"/${PN}-3.2_pre7-abort-on-modprobe-failure.patch
	epatch "${FILESDIR}"/${PN}-3.2.2-handle-dupliate-aliases.patch #149426
	epatch "${FILESDIR}"/${PN}-3.6-hidden-dirs.patch #245271
	epatch "${FILESDIR}"/${P}-skip-sys-check.patch #258442

	# make sure we link dynamically with zlib; our zlib.so is in /lib vs
	# /usr/lib so it's safe to link with.  fixes ugly textrels as well.
	sed -i \
		-e 's:-Wl,-Bstatic -lz -Wl,-Bdynamic:-lz:' \
		configure || die

	# make sure we don't try to regen the manpages
	touch *.5 *.8
}

src_compile() {
	# Configure script uses BUILDCFLAGS for cross-compiles but this
	# defaults to CFLAGS which can be bad mojo
	export BUILDCFLAGS=-pipe
	export BUILDCC=$(tc-getBUILD_CC)

	if use old-linux ; then
		einfo "Building modutils ..."
		cd "${WORKDIR}"/modutils-${MODUTILS_PV}
		econf \
			--disable-strip \
			--prefix=/ \
			--enable-insmod-static \
			--disable-zlib \
			|| die "econf failed"
		emake || die "emake modutils failed"

		einfo "Building module-init-tools ..."
		cd "${S}"
	fi

	econf \
		--prefix=/ \
		--enable-zlib \
		|| die "econf failed"
	emake || die "emake module-init-tools failed"
}

modutils_src_install() {
	cd "${WORKDIR}"/modutils-${MODUTILS_PV}
	einstall prefix="${D}" || die
	docinto modutils-${MODUTILS_PV}
	dodoc CREDITS ChangeLog NEWS README TODO

	# remove man pages provided by the man-pages package now #124127
	rm -r "${D}"/usr/share/man/man2

	cd "${S}"
	# This copies the old version of modutils to *.old so it still works
	# with kernels <= 2.4; new versions will execve() the .old version if
	# a 2.4 kernel is running...
	# This code was borrowed from the module-init-tools Makefile
	local runme f
	for f in lsmod modprobe rmmod depmod insmod insmod.static modinfo ; do
		if [[ -L ${D}/sbin/${f} ]] ; then
			einfo "Moving symlink $f to ${f}.old"
			#runme = the target of the symlink with a .old tagged on.
			runme=$(ls -l "${D}"/sbin/${f} | sed 's/.* -> //').old
			[[ ! -e ${D}/sbin/${runme} ]] || einfo "${D}/sbin/${runme} not found"
			dosym ${runme} /sbin/${f} || die
		elif [[ -e ${D}/sbin/${f} ]] ; then
			einfo "Moving executable $f to ${f}.old"
		fi
		mv -f "${D}"/sbin/${f} "${D}"/sbin/${f}.old
	done
	# Move the man pages as well.  We only do this for the man pages of the
	# tools that module-init-tools will replace.
	for f in "${D}"/usr/share/man/man8/{lsmod,modprobe,rmmod,depmod,insmod}.8
	do
		mv -f ${f} ${f%\.*}.old.${f##*\.}
	done
	# Fix the ksyms links #35601
	for f in ksyms kallsyms ; do
		dosym insmod.old /sbin/${f}
		dosym insmod.static.old /sbin/${f}.static
	done
}

src_install() {
	use old-linux && modutils_src_install

	cd "${S}"
	emake install DESTDIR="${D}" || die
	dosym modprobe.conf.5 /usr/share/man/man5/modprobe.d.5

	# Install compat symlink
	dosym ../bin/lsmod /sbin/lsmod
	use old-linux && dosym ../sbin/insmod.old /bin/lsmod.old
	# Install the modules.conf2modprobe.conf tool, so we can update
	# modprobe.conf.
	into /
	dosbin "${S}"/generate-modprobe.conf || die
	newsbin "${FILESDIR}"/update-modules-3.5.sh update-modules || die
	doman "${FILESDIR}"/update-modules.8

	doman *.[1-8]
	docinto /
	dodoc AUTHORS ChangeLog INSTALL NEWS README TODO
}

pkg_postinst() {
	# cheat to keep users happy
	if grep -qs modules-update "${ROOT}"/etc/init.d/modules ; then
		sed -i 's:modules-update:update-modules:' "${ROOT}"/etc/init.d/modules
	fi
}
