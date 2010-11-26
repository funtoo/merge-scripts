# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/openvz-sources/openvz-sources-2.6.18.028.066.7.ebuild,v 1.1 2009/11/26 19:12:49 pva Exp $

ETYPE="sources"

CKV=2.6.18
OKV=$CKV
OVZ_KERNEL="028stab070"
OVZ_REV="14"
OVZ_KV=${OVZ_KERNEL}.${OVZ_REV}
if [[ ${PR} == "r0" ]]; then
	KV_FULL=${CKV}-rhel5-openvz-${OVZ_KV}
else
	KV_FULL=${CKV}-rhel5-openvz-${OVZ_KV}-${PR}
fi
EXTRAVERSION=-${OVZ_KV}
KERNEL_URI="mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/linux-${CKV}.tar.bz2"

inherit kernel-2
detect_version

DEPEND="<=sys-fs/udev-147"
KEYWORDS="amd64 x86"
IUSE=""
DESCRIPTION="Full Linux kernel sources - RHEL5 kernel with OpenVZ patchset"
HOMEPAGE="http://www.openvz.org"
MAINPATCH="patch-194.26.1.el5.${OVZ_KV}-combined.gz"
SRC_URI="${KERNEL_URI}
	http://download.openvz.org/kernel/branches/rhel5-${CKV}/${OVZ_KV}/configs/kernel-${CKV}-i686-ent.config.ovz
	http://download.openvz.org/kernel/branches/rhel5-${CKV}/${OVZ_KV}/configs/kernel-${CKV}-x86_64.config.ovz
	http://download.openvz.org/kernel/branches/rhel5-${CKV}/${OVZ_KV}/patches/$MAINPATCH"

UNIPATCH_STRICTORDER=1
UNIPATCH_LIST="$DISTDIR/$MAINPATCH"

#			${FILESDIR}/${PN}-2.6.18.028.064.7-bridgemac.patch
#			${FILESDIR}/${PN}-2.6.18.028.068.3-cpu.patch
#			${FILESDIR}/uvesafb-0.1-rc3-2.6.18-openvz-028.066.10.patch"

K_EXTRAEINFO="
This OpenVZ kernel uses RHEL5 (Red Hat Enterprise Linux 5) patch set.
This patch set is maintained by Red Hat for enterprise use, and contains
further modifications by the OpenVZ development team.

Red Hat typically only ensures that their kernels build using their
own official kernel configurations. Significant variations from these
configurations can result in build failures.

For best results, always start with a .config provided by the OpenVZ 
team from:

http://wiki.openvz.org/Download/kernel/rhel6/${OVZ_KERNEL}.

On amd64 and x86 arches, one of these configurations has automatically been
enabled in the kernel source tree that was just installed for you.

Slight modifications to the kernel configuration necessary for booting
are usually fine. If you are using genkernel, the default configuration
should be sufficient for your needs."

K_EXTRAEWARN="THIS KERNEL MUST BE BUILT WITH GCC-4.1 - use gcc-config
prior to building kernel."

src_install() {
	kernel-2_src_install
	cp $DISTDIR/kernel-${CKV}-i686-ent.config.ovz ${D}/usr/src/linux-${KV_FULL}/arch/x86/configs/defconfig 
	cp $DISTDIR/kernel-${CKV}-x86_64.config.ovz ${D}/usr/src/linux-${KV_FULL}/arch/x86_64/configs/defconfig 
	[ "$ARCH" = "amd64" ] && cp $DISTDIR/kernel-${CKV}-x86_64.config.ovz ${D}/usr/src/linux-${KV_FULL}/.config
	[ "$ARCH" = "x86" ] && cp $DISTDIR/kernel-${CKV}-i686-ent.config.ovz ${D}/usr/src/linux-${KV_FULL}/.config
}
pkg_postinst() {
	kernel-2_pkg_postinst
}
