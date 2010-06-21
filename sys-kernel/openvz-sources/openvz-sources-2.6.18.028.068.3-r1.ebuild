# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/openvz-sources/openvz-sources-2.6.18.028.066.7.ebuild,v 1.1 2009/11/26 19:12:49 pva Exp $

ETYPE="sources"

PATCHV="164.11.1.el5"
CKV=2.6.18
OKV=${OKV:-${CKV}}
if [[ ${PR} == "r0" ]]; then
KV_FULL=${CKV}-${PN/-*}-028.068.3
else
KV_FULL=${CKV}-${PN/-*}-028.068.3-${PR}
fi
OVZ_KERNEL="028stab068"
OVZ_REV="3"
EXTRAVERSION=-${OVZ_KERNEL}
CONFIG_URI="http://download.openvz.org/kernel/branches/rhel5-${CKV}/${OVZ_KERNEL}.${OVZ_REV}/configs/"
KERNEL_URI="mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/linux-${OKV}.tar.bz2"

inherit kernel-2
detect_version

# gcc 4.1 to compile

PDEPEND="=sys-devel/gcc-4.1*"
KEYWORDS="amd64 ppc64 sparc x86"
IUSE=""
DESCRIPTION="Full sources including OpenVZ patchset for the 2.6.18 kernel tree"
HOMEPAGE="http://www.openvz.org"
AMD64_CONFIG="kernel-${CKV}-x86_64.config.ovz"
X86_CONFIG="kernel-${CKV}-i686-ent.config.ovz"
SRC_URI="${KERNEL_URI} 
	${ARCH_URI}
	http://download.openvz.org/kernel/branches/rhel5-${CKV}/${OVZ_KERNEL}.${OVZ_REV}/patches/patch-${PATCHV}.${OVZ_KERNEL}.${OVZ_REV}-combined.gz
	x86? ( $CONFIG_URI/$X86_CONFIG )
	amd64? ( $CONFIG_URI/$AMD64_CONFIG )
	"

UNIPATCH_STRICTORDER=1
UNIPATCH_LIST="${DISTDIR}/patch-${PATCHV}.${OVZ_KERNEL}.${OVZ_REV}-combined.gz
			${FILESDIR}/${PN}-2.6.18.028.064.7-bridgemac.patch
			${FILESDIR}/${PN}-2.6.18.028.068.3-cpu.patch
			${FILESDIR}/uvesafb-0.1-rc3-2.6.18-openvz-028.066.10.patch"

K_EXTRAEINFO="This openvz kernel uses RHEL5 patchset instead of vanilla kernel.
This patchset considered to be more stable and supported by upstream.

This kernel is intended to be built using a specific configuration, and fails to
build in many configurations so please always start with a .config provided by
the OpenVZ team from http://wiki.openvz.org/Download/kernel/rhel5/${OVZ_KERNEL}.

On amd64 and x86 arches, one of these configurations has automatically been
copied into place for you.

Customize the config by enabling boot-related device drivers and filesystems
so they are part of the kernel rather than modules, or use an initrd/initramfs
to ensure that critical boot modules can be loaded."

K_EXTRAEWARN="This kernel is stable only when built with gcc-4.1.x and is known
to oops in random places if built with newer compilers. To build, use gcc-config
to switch to gcc-4.1, source /etc/profile and then build bzImage and modules.
Then use gcc-config to switch back to your default compiler."

src_install() {
	kernel-2_src_install
	local CDEST="${D}/usr/src/linux-${KV_FULL}/configs"
	install -d $CDEST || die
	[ "$ARCH" = "amd64" ] && cp $DISTDIR/$AMD64_CONFIG $CDEST
	[ "$ARCH" = "x86" ] && cp $DISTDIR/$X86_CONFIG $CDEST
}

pkg_postinst() {
	kernel-2_pkg_postinst

	# All this below is here to copy the OpenVZ default config into place.
	# The openvz-sources enterprise kernels should be built using these configs
	# as a starting point.

	[ ! -d "$ROOT/usr/src/linux-${KV_FULL}" ] && return 0
	cd "$ROOT/usr/src/linux-${KV_FULL}"
	[ -e .config ] && return 0
	local myconfig
	if [ "$ARCH" = "amd64" ]
	then
		myconfig=$AMD64_CONFIG
	elif [ "$ARCH" = "x86" ]
	then
		myconfig=$X86_CONFIG
	fi
	if [ -n "$myconfig" ]
	then
		einfo "Copying $myconfig into place as default config..."
		cp configs/$myconfig .config
	fi
}
