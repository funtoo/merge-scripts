EAPI="3"
ETYPE="sources"
inherit kernel-2 eutils

KV="${PV%.*}"
KV_FULL="${PN}-${PVR}"
SYSRESC_REL="${PV##*.}"
S=${WORKDIR}/linux-${KV}
DESCRIPTION="System Rescue CD Full sources for the Linux kernel, including gentoo and sysresccd patches."
SRC_URI="mirror://kernel/linux/kernel/v2.6/linux-2.6.35.tar.bz2 http://www.funtoo.org/archive/sysrescue-std-sources/std-sources-${PV}-patches-config.tar.xz"
PROVIDE="virtual/linux-sources"
HOMEPAGE="http://kernel.sysresccd.org"
LICENSE="GPL-2"
SLOT="${KV}"
KEYWORDS="-* ~amd64 ~x86"
IUSE=""

src_unpack()
{
	unpack ${A}
	ln -s linux-${KV} linux
	mv linux-2.6.35 linux-${KV_FULL}
	cd linux-${KV_FULL}
	epatch ../${SYSRESC_REL}/std-sources-2.6.35_01-fc14-082.patch || die "std-sources fc14 patch failed."
	epatch ../${SYSRESC_REL}/std-sources-2.6.35_02-squashxz.patch || die "std-sources squashfs-xz patch failed."
	epatch ../${SYSRESC_REL}/std-sources-2.6.35_03-aufs21.patch || die "std-sources aufs2 patch failed."
	epatch ../${SYSRESC_REL}/std-sources-2.6.35_04-reiser4.patch || die "std-sources reiser4 patch failed."
	epatch ../${SYSRESC_REL}/std-sources-2.6.35_05-speakup.patch || die "std-sources speakup patch failed."
	epatch ../${SYSRESC_REL}/std-sources-2.6.35_06-update-atl1c.patch || die "std-sources alt1c patch failed."
	sedlockdep='s:.*#define MAX_LOCKDEP_SUBCLASSES.*8UL:#define MAX_LOCKDEP_SUBCLASSES 16UL:'
	sed -i -e "${sedlockdep}" include/linux/lockdep.h || die
	agpdisable='s:int nouveau_agpmode = .*:int nouveau_agpmode = 0;:g'
	sed -i -e "${agpdisable}" drivers/gpu/drm/nouveau/nouveau_drv.c
	oldextra=$(cat Makefile | grep "^EXTRAVERSION")
	sed -i -e "s/${oldextra}/EXTRAVERSION = -sysrescue-std${SYSRESC_REL}/" Makefile || die
	cp ../${SYSRESC_REL}/kernelcfg/config-2.6.35-std${SYSRESC_REL}.x86_64 arch/x86/configs/x86_64_defconfig || die
	cp ../${SYSRESC_REL}/kernelcfg/config-2.6.35-std${SYSRESC_REL}.i686 arch/x86/configs/i386_defconfig || die
	rm -f .config || die
}
