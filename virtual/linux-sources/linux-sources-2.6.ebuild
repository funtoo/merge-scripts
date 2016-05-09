# Distributed under the terms of the GNU General Public License v2

EAPI=2

DESCRIPTION="Virtual for Linux kernel sources"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="*"
IUSE="hardened"

DEPEND=""
RDEPEND="|| (
		hardened? ( >=sys-kernel/hardened-sources-2.6 )
		>=sys-kernel/dummy-sources-4.5.3
		>=sys-kernel/debian-sources-2.6
		>=sys-kernel/aufs-sources-2.6
		>=sys-kernel/bliss-kernel-2.6
		>=sys-kernel/gentoo-sources-2.6
		>=sys-kernel/cell-sources-2.6
		>=sys-kernel/centos7plus-sources-2.6
		>=sys-kernel/ck-sources-2.6
		>=sys-kernel/git-sources-2.6
		>=sys-kernel/hardened-sources-2.6
		>=sys-kernel/mips-sources-2.6
		>=sys-kernel/mm-sources-2.6
		>=sys-kernel/openvz-rhel5-stable-2.6
		>=sys-kernel/openvz-rhel6-stable-2.6
		>=sys-kernel/openvz-rhel6-test-2.6
		>=sys-kernel/openvz-sources-2.6
		>=sys-kernel/pf-sources-2.6
		>=sys-kernel/rhel7-sources-2.6
		>=sys-kernel/sysrescue-std-sources-2.6
		>=sys-kernel/tuxonice-sources-2.6
		>=sys-kernel/ubuntu-sources-2.6
		>=sys-kernel/usermode-sources-2.6
		>=sys-kernel/vanilla-sources-2.6
		>=sys-kernel/xbox-sources-2.6
		>=sys-kernel/xen-sources-2.6
		>=sys-kernel/zen-sources-2.6
		sys-kernel/vserver-sources
	)"
