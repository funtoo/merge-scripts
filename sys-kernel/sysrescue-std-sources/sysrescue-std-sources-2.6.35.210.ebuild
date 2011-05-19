# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/openvz-sources/openvz-sources-2.6.18.028.066.7.ebuild,v 1.1 2009/11/26 19:12:49 pva Exp $

EAPI=3

inherit mount-boot

SLOT=$PVR
CKV=2.6.35
SYSRESC_REL="${PV##*.}"
KV_FULL=${PN}-${PVR}
KERNEL_ARCHIVE="linux-${CKV}.tar.bz2"
KERNEL_URI="mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/${KERNEL_ARCHIVE}"
RESTRICT="binchecks strip"

LICENSE="GPL-2"
KEYWORDS="x86 amd64"
IUSE="binary"
DEPEND="binary? ( >=sys-kernel/genkernel-3.4.12.6-r4 )"
RDEPEND="binary? ( >=sys-fs/udev-160 )"
DESCRIPTION="System Rescue CD Full sources for the Linux kernel, including gentoo and sysresccd patches."
HOMEPAGE="http://kernel.sysresccd.org"
SRC_URI="${KERNEL_URI} http://www.funtoo.org/archive/sysrescue-std-sources/std-sources-${PV}-patches-config.tar.xz"
S="$WORKDIR/linux-${CKV}"
S2="$WORKDIR/${SYSRESC_REL}"

src_unpack() {
	unpack ${KERNEL_ARCHIVE} std-sources-${PV}-patches-config.tar.xz
}

apply() {
	p=$1; shift
	case "${p##*.}" in
		gz)
			ca="gzip -dc"
			;;
		bz2)
			ca="bzip2 -dc"
			;;
		xz)
			ca="xz -dc"
			;;
		*)
			ca="cat"
			;;
	esac
	[ ! -e $p ] && die "patch $p not found"
	echo "Applying patch $p"; $ca $p | patch -s $* || die "patch $p failed"
}

pkg_setup() {
	case $ARCH in
		x86)
			defconfig_src=std${SYSRESC_REL}.i586
			;;
		amd64)
			defconfig_src=std${SYSRESC_REL}.x86_64
			;;
		*)
			die "unsupported ARCH: $ARCH"
			;;
	esac
	defconfig_src="${S2}/kernelcfg/config-${CKV}-${defconfig_src}"
	unset ARCH; unset LDFLAGS #will interfere with Makefile if set
}

src_prepare() {
	apply $S2/std-sources-2.6.35_01-fc14-088.patch -p1
	apply $S2/std-sources-2.6.35_02-squashxz.patch -p1
	apply $S2/std-sources-2.6.35_03-aufs.patch -p1
	apply $S2/std-sources-2.6.35_04-reiser4.patch -p1
	apply $S2/std-sources-2.6.35_05-speakup.patch -p1
	apply $S2/std-sources-2.6.35_06-update-atl1c.patch -p1
	sedlockdep='s:.*#define MAX_LOCKDEP_SUBCLASSES.*8UL:#define MAX_LOCKDEP_SUBCLASSES 16UL:'
	sed -i -e "${sedlockdep}" include/linux/lockdep.h || die
	agpdisable='s:int nouveau_agpmode = .*:int nouveau_agpmode = 0;:g'
	sed -i -e "${agpdisable}" drivers/gpu/drm/nouveau/nouveau_drv.c
	oldextra=$(cat Makefile | grep "^EXTRAVERSION")
	sed -i -e "s/${oldextra}/EXTRAVERSION = -sysrescue-std${SYSRESC_REL}/" Makefile || die
	cp $S2/kernelcfg/config-2.6.35-std${SYSRESC_REL}.x86_64 arch/x86/configs/x86_64_defconfig || die
	cp $S2/kernelcfg/config-2.6.35-std${SYSRESC_REL}.i586 arch/x86/configs/i386_defconfig || die
	rm -f .config >/dev/null
	make -s mrproper || die "make mrproper failed"
	make -s include/linux/version.h || die "make include/linux/version.h failed"
}

src_compile() {
	! use binary && return
	install -d ${WORKDIR}/out/{lib,boot}
	install -d ${T}/{cache,twork}
	install -d $WORKDIR/build $WORKDIR/out/lib/firmware
	DEFAULT_KERNEL_SOURCE="${S}" INSTALL_FW_PATH=${WORKDIR}/out/lib/firmware CMD_KERNEL_DIR="${S}" genkernel ${GKARGS} \
		--no-save-config \
		--kernel-config="$defconfig_src" \
		--kernname="${PN/-sources/}" \
		--build-src="$S" \
		--build-dst=${WORKDIR}/build \
		--makeopts="${MAKEOPTS}" \
		--firmware-dst=${WORKDIR}/out/lib/firmware \
		--cachedir="${T}/cache" \
		--tempdir="${T}/twork" \
		--logfile="${WORKDIR}/genkernel.log" \
		--bootdir="${WORKDIR}/out/boot" \
		--lvm \
		--luks \
		--iscsi \
		--module-prefix="${WORKDIR}/out" \
		all || die "genkernel failed"
}

src_install() {
	# copy sources into place:
	dodir /usr/src
	cp -a ${S} ${D}/usr/src/linux-${P} || die
	cd ${D}/usr/src/linux-${P}
	# if we didn't use genkernel, we're done:
	use binary || return
	# prep sources after compile and copy binaries into place:
	make -s clean || die "make clean failed"
	cp -a ${WORKDIR}/out/* ${D}/ || die "couldn't copy output files into place"
	# module symlink fixup:
	rm -f ${D}/lib/modules/*/source || die
	rm -f ${D}/lib/modules/*/build || die
	cd ${D}/lib/modules
	local moddir="$(ls -d 2*)"
	ln -s /usr/src/linux-${P} ${D}/lib/modules/${moddir}/source || die
	ln -s /usr/src/linux-${P} ${D}/lib/modules/${moddir}/build || die
}
