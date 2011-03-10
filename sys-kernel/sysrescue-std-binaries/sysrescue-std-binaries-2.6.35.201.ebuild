# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/openvz-sources/openvz-sources-2.6.18.028.066.7.ebuild,v 1.1 2009/11/26 19:12:49 pva Exp $

inherit mount-boot

EAPI=2
SLOT=0
DEPEND="=sys-kernel/${P/-binaries/-sources} >=sys-kernel/genkernel-3.4.12.6-r3"
KEYWORDS="~amd64 ~x86"
IUSE=""
DESCRIPTION="System Rescue CD Full sources for the Linux kernel, including gentoo and sysresccd patches - initrd and bzImage"
HOMEPAGE="http://kernel.sysresccd.org"
S="${WORKDIR}/linux-${P/-binaries/-sources}"

src_prepare() {
	# copy installed kernel sources to temp dir to do our build:
	cp -a $ROOT/usr/src/linux-${P/-binaries/-sources} ${S} || die "couldn't copy original source"
}

src_compile() {
	install -d ${WORKDIR}/out/{lib,boot/grub}
	install -d ${T}/{cache,twork}
	local kcfg
	if [ "$ARCH" = "amd64" ]
	then
		kcfg="$S/arch/x86/configs/x86_64_defconfig"
	elif [ "$ARCH" = "x86" ]
	then
		kcfg="$S/arch/x86/configs/i386_defconfig"
	else
		die "unrecognized ARCH: $ARCH"
	fi
	unset ARCH # interferes with kernel Makefile
	unset LDFLAGS
	install -d $WORKDIR/out/lib/firmware
	DEFAULT_KERNEL_SOURCE="${S}" INSTALL_FW_PATH=${WORKDIR}/out/lib/firmware CMD_KERNEL_DIR="${S}" genkernel ${GKARGS} \
		--no-mrproper \
		--no-save-config \
		--kernel-config=$kcfg \
		--kernname="${PN/-binaries/}" \
		--kerneldir="${S}" \
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
	cp -a ${WORKDIR}/out/* ${D}/ || die "couldn't copy output files into place"
}
