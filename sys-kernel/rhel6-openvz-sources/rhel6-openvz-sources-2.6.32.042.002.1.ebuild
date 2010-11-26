# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/openvz-sources/openvz-sources-2.6.18.028.066.7.ebuild,v 1.1 2009/11/26 19:12:49 pva Exp $

EAPI=2
ETYPE="sources"

CKV=2.6.32
OKV=$CKV
OVZ_KERNEL="042test002"
OVZ_REV="1"
OVZ_KV=${OVZ_KERNEL}.${OVZ_REV}
if [[ ${PR} == "r0" ]]; then
	KV_FULL=${CKV}-rhel6-openvz-${OVZ_KV}
else
	KV_FULL=${CKV}-rhel6-openvz-${OVZ_KV}-${PR}
fi
EXTRAVERSION=-${OVZ_KV}
KERNEL_URI="mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/linux-${CKV}.tar.bz2"

inherit kernel-2
detect_version

DEPEND=">=sys-fs/udev-147"
KEYWORDS="amd64 x86"
IUSE=""
DESCRIPTION="Full Linux kernel sources - RHEL6 kernel with OpenVZ patchset"
HOMEPAGE="http://www.openvz.org"
MAINPATCH="patch-${OVZ_KV}-combined.gz"
SRC_URI="${KERNEL_URI}
	http://download.openvz.org/kernel/branches/rhel6-${CKV}/${OVZ_KV}/configs/config-${CKV}-${OVZ_KV}.i686
	http://download.openvz.org/kernel/branches/rhel6-${CKV}/${OVZ_KV}/configs/config-${CKV}-${OVZ_KV}.x86_64
	http://download.openvz.org/kernel/branches/rhel6-${CKV}/${OVZ_KV}/patches/$MAINPATCH"

UNIPATCH_STRICTORDER=1
UNIPATCH_LIST="$DISTDIR/$MAINPATCH"

#			${FILESDIR}/${PN}-2.6.18.028.064.7-bridgemac.patch
#			${FILESDIR}/${PN}-2.6.18.028.068.3-cpu.patch
#			${FILESDIR}/uvesafb-0.1-rc3-2.6.18-openvz-028.066.10.patch"

K_EXTRAEINFO="
This OpenVZ kernel uses RHEL6 (Red Hat Enterprise Linux 6) patch set.
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

src_install() {
	kernel-2_src_install
	cp $DISTDIR/config-${CKV}-${OVZ_KV}.i686 ${D}/usr/src/linux-${KV_FULL}/arch/x86/configs/i386_defconfig 
	cp $DISTDIR/config-${CKV}-${OVZ_KV}.x86_64 ${D}/usr/src/linux-${KV_FULL}/arch/x86/configs/x86_64_defconfig 
	[ "$ARCH" = "amd64" ] && cp $DISTDIR/config-${CKV}-${OVZ_KV}.x86_64 ${D}/usr/src/linux-${KV_FULL}/.config
	[ "$ARCH" = "x86" ] && cp $DISTDIR/config-${CKV}-${OVZ_KV}.i686 ${D}/usr/src/linux-${KV_FULL}/.config
}

pkg_postinst() {
	kernel-2_pkg_postinst
}
