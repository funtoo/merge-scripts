# Copyright (C) 2013 Jonathan Vasquez <jvasquez1011@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

GITHUB_USER="fearedbliss"
GITHUB_REPO="Bliss-Initramfs-Creator"
GITHUB_TAG="${PV}"

DESCRIPTION="Creates an initramfs for ZFS"
HOMEPAGE="https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
SRC_URI="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/${GITHUB_TAG}.tar.gz -> ${P}.tar.gz"

RESTRICT="mirror strip"
LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE="luks"

RDEPEND="
	app-arch/cpio
	app-shells/bash
	sys-kernel/spl
	sys-fs/zfs
	sys-fs/zfs-kmod
	sys-apps/kmod
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
