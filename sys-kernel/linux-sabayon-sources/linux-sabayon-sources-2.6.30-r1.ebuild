# Copyright 2004-2009 Sabayon Linux
# Distributed under the terms of the GNU General Public License v2

ETYPE="sources"
K_WANT_GENPATCHES=""
K_GENPATCHES_VER=""
K_SABPATCHES_VER="3"
K_SABPATCHES_PKG="${PV}-${K_SABPATCHES_VER}.tar.bz2"
inherit kernel-2
detect_version
detect_arch

DESCRIPTION="Official Sabayon Linux Standard kernel sources"
RESTRICT="nomirror"
IUSE=""
UNIPATCH_STRICTORDER="yes"
KEYWORDS="~amd64 ~x86"
HOMEPAGE="http://www.sabayonlinux.org"
SRC_URI="${KERNEL_URI}
        http://distfiles.sabayonlinux.org/${CATEGORY}/linux-sabayon-patches/${K_SABPATCHES_PKG}"

KV_FULL=${KV_FULL/linux/sabayon}
K_NOSETEXTRAVERSION="1"
EXTRAVERSION=${EXTRAVERSION/linux/sabayon}
SLOT="${PVR/-r0/}"
S="${WORKDIR}/linux-${KV_FULL}"

# patches
UNIPATCH_LIST="${DISTFILES}/${K_SABPATCHES_PKG}"

src_unpack() {

	kernel-2_src_unpack
	cd "${S}"

	# manually set extraversion
	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${EXTRAVERSION}:" Makefile

}

src_install() {
	kernel-2_src_install
	cd ${D}/usr/src/${KV_FULL}
	local oldarch=${ARCH}
	DFLTCONFIG=${PF/-r0/}
	echo "DFLTCONFIG is ${DFLTCONFIG}"
	DFLTCONFIG=${DFLTCONFIG/-sources/}
	echo "DFLTCONFIG is ${DFLTCONFIG}"
	cp ${FILESDIR}/${DFLTCONFIG}-${ARCH}.config .config || die "cannot copy kernel config"
	unset ARCH
	make modules_prepare || die "failed to run modules_prepare"
	rm .config
	ARCH=${oldarch}
}
