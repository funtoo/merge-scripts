# Copyright (C) 2013 Jonathan Vasquez <jvasquez1011@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

GITHUB_USER="fearedbliss"
GITHUB_REPO="Bliss-Initramfs-Creator"
GITHUB_TAG="${PV}"

DESCRIPTION="Creates an initramfs for ZFS, LVM, RAID, LVM on RAID, Normal, and their Encrypted counterparts."
HOMEPAGE="https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
SRC_URI="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/${GITHUB_TAG}.tar.gz -> ${P}.tar.gz"

RESTRICT="mirror strip"
LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE="zfs raid lvm luks"

RDEPEND="
	>=dev-lang/python-3.3
	app-arch/cpio
	app-shells/bash
	sys-apps/kmod

	zfs? ( sys-kernel/spl
		   sys-fs/zfs
	       sys-fs/zfs-kmod )

	raid? ( sys-fs/mdadm )

	lvm? ( sys-fs/lvm2 )

	luks? ( sys-fs/cryptsetup 
			app-crypt/gnupg )"

src_unpack() {
	unpack ${A}
	mv ${WORKDIR}/${GITHUB_REPO}-${PV} ${WORKDIR}/${P}
}

src_install() {
	mkdir -p ${D}/opt/${PN} && cd ${D}/opt/${PN}
	cp -a ${S}/* .
}
