# Copyright 2004-2009 Sabayon Linux
# Distributed under the terms of the GNU General Public License v2

ETYPE="sources"
K_WANT_GENPATCHES=""
K_GENPATCHES_VER=""
K_SABPATCHES_VER="2"
K_SABPATCHES_PKG="${PV}-${K_SABPATCHES_VER}.tar.bz2"
inherit kernel-2
detect_version
detect_arch

DESCRIPTION="Official Sabayon Linux Standard kernel sources"
RESTRICT="nomirror"
IUSE=""
UNIPATCH_STRICTORDER="yes"
KEYWORDS="~amd64 ~x86"
HOMEPAGE="http://www.sabayon.org"
SRC_URI="${KERNEL_URI}
        http://distfiles.sabayonlinux.org/${CATEGORY}/linux-sabayon-patches/${K_SABPATCHES_PKG}"

KV_FULL=${KV_FULL/linux/sabayon}
K_NOSETEXTRAVERSION="1"
EXTRAVERSION=${EXTRAVERSION/linux/sabayon}
SLOT="${PV}"
S="${WORKDIR}/linux-${KV_FULL}"

# patches
UNIPATCH_LIST="
	${DISTFILES}/${K_SABPATCHES_PKG}
	${FILESDIR}/${PV}/cfq-iosched-IO-latency.patch
"

src_unpack() {

	kernel-2_src_unpack
	cd "${S}"

	# manually set extraversion
	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${EXTRAVERSION}:" Makefile

}

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
	cp ${FILESDIR}/${P/-sources}-${ARCH}.config .config || die "cannot copy kernel config"
	unset ARCH
	make modules_prepare || die "failed to run modules_prepare"
	rm .config || die "cannot remove .config"
	rm Makefile || die "cannot remove Makefile"
	ARCH=${oldarch}

}
