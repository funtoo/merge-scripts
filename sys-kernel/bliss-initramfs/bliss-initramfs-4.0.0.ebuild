# Copyright (C) 2013 Jonathan Vasquez <fearedbliss@funtoo.org>
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

GITHUB_USER="fearedbliss"
GITHUB_REPO="Bliss-Initramfs-Creator"
GITHUB_TAG="${PV}"

DESCRIPTION="Allows you to create multiple types of initramfs"
HOMEPAGE="https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
SRC_URI="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/${GITHUB_TAG}.tar.gz -> ${P}.tar.gz"

RESTRICT="mirror strip"
LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="zfs raid lvm luks"

RDEPEND="
	>=dev-lang/python-3.3
	app-arch/cpio
	app-shells/bash
	sys-apps/kmod
	sys-apps/grep
	sys-apps/util-linux

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
