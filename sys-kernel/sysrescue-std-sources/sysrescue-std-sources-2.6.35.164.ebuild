ETYPE="sources"
inherit kernel-2 eutils

KV=2.6.35
KV_FULL="${PN}-${PVR}"
S=${WORKDIR}/linux-${KV}
DESCRIPTION="System Rescue CD Full sources for the Linux kernel, including gentoo and sysresccd patches."
SRC_URI="mirror://kernel/linux/kernel/v2.6/linux-2.6.35.tar.bz2"
PROVIDE="virtual/linux-sources"
HOMEPAGE="http://kernel.sysresccd.org"
LICENSE="GPL-2"
SLOT="${KV}"
KEYWORDS="-* amd64 x86"
IUSE=""
SYSRESC_REL=164

src_unpack()
{
	unpack linux-2.6.35.tar.bz2
	ln -s linux-${KV} linux
	mv linux-2.6.35 linux-${KV_FULL}
	cd linux-${KV_FULL}
	epatch ${FILESDIR}/std-sources-2.6.35_01-fc14-062.patch.bz2 || die "std-sources fc14 patch failed."
	epatch ${FILESDIR}/std-sources-2.6.35_02-sqlzma40.patch.bz2 || die "std-sources sqlzma40 patch failed."
	epatch ${FILESDIR}/std-sources-2.6.35_03-aufs2.patch.bz2 || die "std-sources aufs2 patch failed."
	epatch ${FILESDIR}/std-sources-2.6.35_04-reiser4.patch.bz2 || die "std-sources reiser4 patch failed."
	epatch ${FILESDIR}/std-sources-2.6.35_05-loopaes.patch.bz2 || die "std-sources loopaes patch failed."
	epatch ${FILESDIR}/std-sources-2.6.35_06-speakup.patch.bz2 || die "std-sources speakup patch failed."
	epatch ${FILESDIR}/std-sources-2.6.35_07-xz-20100702.patch.bz2 || die "std-sources xz patch failed."
	sedlockdep='s:.*#define MAX_LOCKDEP_SUBCLASSES.*8UL:#define MAX_LOCKDEP_SUBCLASSES 16UL:'
	sed -i -e "${sedlockdep}" include/linux/lockdep.h || die
	oldextra=$(cat Makefile | grep "^EXTRAVERSION")
	sed -i -e "s/${oldextra}/EXTRAVERSION = -sysrescue-std${SYSRESC_REL}/" Makefile || die
	cp ${FILESDIR}/kernelcfg/config-amd64-2.6.35-std${SYSRESC_REL}.conf arch/x86/configs/x86_64_defconfig || die
	cp ${FILESDIR}/kernelcfg/config-x86-2.6.35-std${SYSRESC_REL}.conf arch/x86/configs/i386_defconfig || die
	rm -f .config || die
}
