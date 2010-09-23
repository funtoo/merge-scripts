# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/vserver-sources/vserver-sources-2.3.0.36.28.ebuild,v 1.1 2010/01/14 09:46:54 hollow Exp $

# DEV NOTES:
# - based on sys-kernel/linux-server plus:
#   - Linux VServer options enabled
#   - More Security frameworks enabled by default

ETYPE="sources"
CKV="2.6.35"
K_USEPV="1"
K_NOSETEXTRAVERSION="1"
UNIPATCH_STRICTORDER="1"
K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="4"
K_KERNEL_SOURCES_PKG="sys-kernel/vserver-sources-${PVR}"
# Security patches for CVE-2010-3081, will be merged in next stable kernel release
K_KERNEL_PATCH_HOTFIXES="${FILESDIR}/hotfixes/2.6.35/linux-2.6.git-c41d68a513c71e35a14f66d71782d27a79a81ea6.patch
        ${FILESDIR}/hotfixes/2.6.35/linux-2.6.git-eefdca043e8391dcd719711716492063030b55ac.patch
        ${FILESDIR}/hotfixes/2.6.35/linux-2.6.git-36d001c70d8a0144ac1d038f6876c484849a74de.patch"
# match vserver-sources
K_KERNEL_DISABLE_PR_EXTRAVERSION="0"
K_KERNEL_SLOT_USEPVR="1"
K_WORKAROUND_SOURCES_COLLISION="1"
K_WORKAROUND_DIFFERENT_EXTRAVERSION="1"
# PLEASE NOTE: grub-handler is known to not work with kernel binary+initramfs installed
# by this package, but grub-0.9x support is going to be dropped and there are no
# releases shipped with it as of today.
inherit sabayon-kernel

############################################
# upstream part

MY_PN="vserver-patches"

KEYWORDS="~amd64 ~hppa ~x86"
IUSE=""

DESCRIPTION="Full sources including Gentoo and Linux-VServer patchsets for the ${KV_MAJOR}.${KV_MINOR} kernel tree."
HOMEPAGE="http://www.gentoo.org/proj/en/vps/"
SRC_URI="${KERNEL_URI} ${GENPATCHES_URI} ${ARCH_URI}
	http://dev.gentoo.org/~hollow/distfiles/${MY_PN}-${CKV}_${PVR}.tar.bz2"

UNIPATCH_LIST="${UNIPATCH_LIST} ${DISTDIR}/${MY_PN}-${CKV}_${PVR}.tar.bz2"

# upstream part
############################################

