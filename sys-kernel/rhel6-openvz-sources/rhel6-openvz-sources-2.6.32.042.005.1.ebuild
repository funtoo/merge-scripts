# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/openvz-sources/openvz-sources-2.6.18.028.066.7.ebuild,v 1.1 2009/11/26 19:12:49 pva Exp $

EAPI=2
ETYPE="sources"

CKV=2.6.32
OKV=$CKV
OVZ_KERNEL="042test005"
OVZ_REV="1"
OVZ_KV=${OVZ_KERNEL}.${OVZ_REV}
OVZ_BRANCH="rhel6"
KV_FULL=${PN}-${PVR}
EXTRAVERSION=-${OVZ_KV}
KERNEL_URI="mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/linux-${CKV}.tar.bz2"

inherit kernel-2
detect_version

KEYWORDS="~amd64 ~x86"
IUSE=""
DESCRIPTION="Full Linux kernel sources - RHEL5 kernel with OpenVZ patchset"
HOMEPAGE="http://www.openvz.org"
MAINPATCH="patch-${OVZ_KV}-combined.gz"
SRC_URI="${KERNEL_URI}
	http://download.openvz.org/kernel/branches/${OVZ_BRANCH}-${CKV}/${OVZ_KV}/configs/config-${CKV}-${OVZ_KV}.i686
	http://download.openvz.org/kernel/branches/${OVZ_BRANCH}-${CKV}/${OVZ_KV}/configs/config-${CKV}-${OVZ_KV}.x86_64
	http://download.openvz.org/kernel/branches/${OVZ_BRANCH}-${CKV}/${OVZ_KV}/patches/$MAINPATCH"

UNIPATCH_STRICTORDER=1
UNIPATCH_LIST="${FILESDIR}/rhel5-openvz-sources-2.6.18.028.064.7-bridgemac.patch"

K_EXTRAEINFO="
This OpenVZ kernel uses RHEL6 (Red Hat Enterprise Linux 6) patch set.
This patch set is maintained by Red Hat for enterprise use, and contains
further modifications by the OpenVZ development team and the Funtoo
Linux project.

Red Hat typically only ensures that their kernels build using their
own official kernel configurations. Significant variations from these
configurations can result in build failures.

For best results, always start with a .config provided by the OpenVZ 
team from:

http://wiki.openvz.org/Download/kernel/${OVZ_BRANCH}/${OVZ_KERNEL}.

On amd64 and x86 arches, one of these configurations has automatically been
enabled in the kernel source tree that was just installed for you.

Slight modifications to the kernel configuration necessary for booting
are usually fine. If you are using genkernel, the default configuration
should be sufficient for your needs."

src_install() {
	kernel-2_src_install
	cp $DISTDIR/config-${CKV}-${OVZ_KV}.i686 ${D}/usr/src/linux-${KV_FULL}/arch/x86/configs/i386_defconfig
	cp $DISTDIR/config-${CKV}-${OVZ_KV}.x86_64 ${D}/usr/src/linux-${KV_FULL}/arch/x86/configs/x86_64_defconfig
	#local MYARCH
	#for MYARCH in i386 x86_64
	#do
	#	# add missing uvesafb config option (came from our patch) to default config
	#	echo "CONFIG_FB_UVESA=y" >> "${D}/usr/src/linux-${KV_FULL}/arch/$MYARCH/defconfig" || die "uvesafb config fail"
	#done
	[ "$ARCH" = "amd64" ] && cp $DISTDIR/config-${CKV}-${OVZ_KV}.x86_64 ${D}/usr/src/linux-${KV_FULL}/.config
	[ "$ARCH" = "x86" ] && cp $DISTDIR/config-${CKV}-${OVZ_KV}.i686 ${D}/usr/src/linux-${KV_FULL}/.config
}

pkg_postinst() {
	kernel-2_pkg_postinst
}
