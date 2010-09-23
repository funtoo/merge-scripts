# Copyright 2004-2010 Sabayon Linux
# Distributed under the terms of the GNU General Public License v2

ETYPE="sources"
K_WANT_GENPATCHES=""
K_GENPATCHES_VER=""
K_SABPATCHES_VER="6"
K_SABKERNEL_NAME="server"
K_ONLY_SOURCES="1"
# Security patches for CVE-2010-3081, will be merged in next stable kernel release
K_KERNEL_PATCH_HOTFIXES="${FILESDIR}/hotfixes/2.6.33/x86-64-compat-test-rax-for-the-syscall-number-not-eax.patch
        ${FILESDIR}/hotfixes/2.6.33/x86-64-compat-retruncate-rax-after-ia32-syscall-entry-tracing.patch
        ${FILESDIR}/hotfixes/2.6.33/compat-make-compat_alloc_user_space-incorporate-the-access_ok.patch"
inherit sabayon-kernel
KEYWORDS="~amd64 ~x86"
DESCRIPTION="Official Sabayon Linux Server kernel sources"
RESTRICT="mirror"
IUSE="sources_standalone"

DEPEND="${DEPEND}
	sources_standalone? ( !=sys-kernel/linux-server-${PVR} )
	!sources_standalone? ( =sys-kernel/linux-server-${PVR} )"

src_compile() {
	kernel-2_src_compile
}

### override sabayon-kernel-src_install()
src_install() {

	local version_h_name="usr/src/linux-${KV_FULL}/include/linux"
	local version_h="${ROOT}${version_h_name}"
	if [ -f "${version_h}" ]; then
		einfo "Discarding previously installed version.h to avoid collisions"
		addwrite "/${version_h_name}"
		rm -f "${version_h}"
	fi

	kernel-2_src_install
	cd "${D}/usr/src/linux-${KV_FULL}"
	local oldarch=${ARCH}
	cp "${FILESDIR}/${P}-${ARCH}.config" .config || die "cannot copy kernel config"
	unset ARCH
	if ! use sources_standalone; then
		make modules_prepare || die "failed to run modules_prepare"
		rm .config || die "cannot remove .config"
		rm Makefile || die "cannot remove Makefile"
		rm include/linux/version.h || die "cannot remove include/linux/version.h"
	fi
	ARCH=${oldarch}

}
