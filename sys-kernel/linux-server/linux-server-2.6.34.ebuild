# Copyright 2004-2009 Sabayon Linux
# Distributed under the terms of the GNU General Public License v2

ETYPE="sources"
K_SABPATCHES_VER="11"
K_KERNEL_PATCH_VER="6"
K_KERNEL_SOURCES_PKG="sys-kernel/linux-server-sources-${PVR}"
K_SABKERNEL_URI_CONFIG="yes"
# Security patches for CVE-2010-3081, will be merged in next stable kernel release
K_KERNEL_PATCH_HOTFIXES="${FILESDIR}/hotfixes/2.6.34/x86-64-compat-test-rax-for-the-syscall-number-not-eax.patch
        ${FILESDIR}/hotfixes/2.6.34/x86-64-compat-retruncate-rax-after-ia32-syscall-entry-tracing.patch
        ${FILESDIR}/hotfixes/2.6.34/compat-make-compat_alloc_user_space-incorporate-the-access_ok.patch"
inherit sabayon-kernel
KEYWORDS="~amd64 ~x86"
DESCRIPTION="Official Sabayon Linux Server kernel image"
RESTRICT="mirror"
