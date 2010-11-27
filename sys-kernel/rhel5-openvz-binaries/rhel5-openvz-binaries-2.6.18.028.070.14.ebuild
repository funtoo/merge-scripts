# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/openvz-sources/openvz-sources-2.6.18.028.066.7.ebuild,v 1.1 2009/11/26 19:12:49 pva Exp $

EAPI=2
SLOT=0
DEPEND="=sys-kernel/${P/-binaries/-sources}
	    >=sys-kernel/genkernel-3.4.10.908
		=sys-devel/gcc-4.1.2*"
RDEPEND=""
KEYWORDS="amd64 x86"
IUSE=""
DESCRIPTION="RHEL5 kernel with OpenVZ patchset - initrd and bzImage"
HOMEPAGE="http://www.openvz.org"

src_prepare() {
	# copy installed kernel sources to temp dir to do our build:
	cp -a $ROOT/usr/src/linux-${P/-binaries/-sources} ${WORKDIR}/ || die "couldn't copy original source"
}

src_compile() {
	install -d ${WORKDIR}/{lib,cache,boot/grub}
	install -d "${S}"/temp
	unset ARCH # interferes with kernel Makefile
	unset LDFLAGS
	DEFAULT_KERNEL_SOURCE="${S}" CMD_KERNEL_DIR="${S}" genkernel ${GKARGS} \
		--no-mrproper \
		--kerneldir="${WORKDIR}/linux-${P/-binaries/-sources}" \
		--cachedir="${WORKDIR}"/cache \
		--makeopts="${MAKEOPTS}" \
		--kernel-cc=gcc-4.1.2 \
		--tempdir="${S}"/temp \
		--logfile="${WORKDIR}"/genkernel.log \
		--bootdir="${WORKDIR}"/boot \
		--mountboot \
		--lvm \
		--luks \
		--iscsi \
		--module-prefix="${WORKDIR}" \
		all || die "genkernel failed"
}

src_install() {
	mv ${WORKDIR}/lib ${D}/ || die "couldn't grab"
	mv ${WORKDIR}/boot ${D}/ || die "couldn't grab2"
}
