# Distributed under the terms of the GNU General Public License v2

EAPI="5"

ETYPE="sources"

K_DEBLOB_AVAILABLE="0"
K_SECURITY_UNSUPPORTED="1"

inherit kernel-2 rpm
detect_version
detect_arch

KV_CLASSIC="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}"
KV_RHEL="${PV/3.10.0.}.el7.centos.plus"
KV_COMPLETE="linux-${KV_CLASSIC}-${KV_RHEL}"

KV_FULL="${KV_FULL/linux/centos7plus}"
EXTRAVERSION="${EXTRAVERSION/linux/centos7plus}"

DESCRIPTION="Red Hat Enterprise Linux kernel sources"
HOMEPAGE="http://www.redhat.com/"

SRC_URI="http://vault.centos.org/7.0.1406/centosplus/Source/SPackages/kernel-plus-${KV_CLASSIC}-${KV_RHEL}.src.rpm -> ${P}.src.rpm"

RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"

IUSE=""

S="${WORKDIR}/linux-${KV_FULL}"

src_unpack() {
	rpm_src_unpack || die
	unpack "./${KV_COMPLETE/.centos.plus/}.tar.xz" || die
	mv "${WORKDIR}/${KV_COMPLETE/.centos.plus/}" "${S}" || die
	rm "${WORKDIR}/${KV_COMPLETE/.centos.plus/}.tar.xz" \
		"${WORKDIR}/debrand-rh-i686-cpu.patch" \
		"${WORKDIR}/debrand-rh_taint.patch" \
		"${WORKDIR}/debrand-single-cpu.patch" \
		"${WORKDIR}/linux-kernel-test.patch" \
		"${S}/configs" || die
	mv "${WORKDIR}/kernel-${KV_CLASSIC}-x86_64.config" "${S}" || die
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-xfs-libcrc.patch

	sed -e "s;^\(EXTRAVERSION =\).*;\1 ${EXTRAVERSION};g" \
		-i "${S}/Makefile" || die
}
