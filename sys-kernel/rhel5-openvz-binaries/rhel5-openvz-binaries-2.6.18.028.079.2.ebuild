# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/openvz-sources/openvz-sources-2.6.18.028.066.7.ebuild,v 1.1 2009/11/26 19:12:49 pva Exp $

inherit mount-boot

EAPI=2
SLOT=0
DEPEND="=sys-kernel/${P/-binaries/-sources}
	    >=sys-kernel/genkernel-3.4.10.908
		=sys-devel/gcc-4.1.2*"
RDEPEND="!>=sys-fs/udev-147 sys-cluster/vzctl"
KEYWORDS="amd64 x86"
IUSE=""
DESCRIPTION="RHEL5 kernel with OpenVZ patchset - initrd and bzImage"
HOMEPAGE="http://www.openvz.org"
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
		kcfg="$S/arch/x86_64/defconfig"
	elif [ "$ARCH" = "x86" ]
	then
		kcfg="$S/arch/i386/defconfig"
	else
		die "unrecognized ARCH: $ARCH"
	fi
	unset ARCH # interferes with kernel Makefile
	unset LDFLAGS

	DEFAULT_KERNEL_SOURCE="${S}" CMD_KERNEL_DIR="${S}" genkernel ${GKARGS} \
		--no-mrproper \
		--no-save-config \
		--kernel-config=$kcfg \
		--kernname="${PN/-binaries/}" \
		--kerneldir="${S}" \
		--makeopts="${MAKEOPTS}" \
		--kernel-cc=gcc-4.1.2 \
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
