# Copyright 2004-2009 Sabayon Linux
# Distributed under the terms of the GNU General Public License v2

ETYPE="sources"
K_WANT_GENPATCHES=""
K_GENPATCHES_VER=""
K_SABPATCHES_VER="9"
K_SABKERNEL_NAME="sabayon"
K_SABKERNEL_URI_CONFIG="yes"
inherit sabayon-kernel
KEYWORDS="~amd64 ~x86"
DESCRIPTION="Official Sabayon Linux Standard kernel sources"
RESTRICT="mirror"
IUSE="sources_standalone"

DEPEND="${DEPEND}
	sources_standalone? ( !=sys-kernel/linux-sabayon-${PVR} )
	!sources_standalone? ( =sys-kernel/linux-sabayon-${PVR} )"

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
	cp ${DISTDIR}/${K_SABKERNEL_CONFIG_FILE} .config || die "cannot copy kernel config"
	unset ARCH
	if ! use sources_standalone; then
		make modules_prepare || die "failed to run modules_prepare"
		rm .config || die "cannot remove .config"
		rm Makefile || die "cannot remove Makefile"
		rm include/linux/version.h || die "cannot remove include/linux/version.h"
	fi
	ARCH=${oldarch}

}
