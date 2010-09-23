# Copyright 2004-2010 Sabayon Linux
# Distributed under the terms of the GNU General Public License v2

ETYPE="sources"
K_SABPATCHES_VER="9"
K_KERNEL_PATCH_VER="4"
K_KERNEL_SOURCES_PKG="sys-kernel/linux-server-sources-${PVR}"
K_SABKERNEL_URI_CONFIG="yes"
# Security patches for CVE-2010-3081, will be merged in next stable kernel release
K_KERNEL_PATCH_HOTFIXES="${FILESDIR}/hotfixes/2.6.35/linux-2.6.git-c41d68a513c71e35a14f66d71782d27a79a81ea6.patch
        ${FILESDIR}/hotfixes/2.6.35/linux-2.6.git-eefdca043e8391dcd719711716492063030b55ac.patch
        ${FILESDIR}/hotfixes/2.6.35/linux-2.6.git-36d001c70d8a0144ac1d038f6876c484849a74de.patch"
inherit sabayon-kernel
KEYWORDS="~amd64 ~x86"
DESCRIPTION="Official Sabayon Linux Server kernel image"
RESTRICT="mirror"
