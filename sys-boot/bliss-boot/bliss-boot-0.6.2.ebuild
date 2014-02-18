# Copyright (C) 2013 Jonathan Vasquez <fearedbliss@funtoo.org>
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

GITHUB_USER="fearedbliss"
GITHUB_REPO="bliss-boot"
GITHUB_TAG="${PV}"

DESCRIPTION="Automatically generates a working bootloader configuration file"
HOMEPAGE="https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
SRC_URI="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/archive/${GITHUB_TAG}.tar.gz -> ${P}.tar.gz"

RESTRICT="mirror strip"
LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="grub2 extlinux"

RDEPEND="
	>=dev-lang/python-3.3
	grub2? ( >=sys-boot/grub-2.00-r7 )
	extlinux? ( sys-boot/syslinux )"

src_install() {
	mkdir -p ${D}/opt/${PN} && cd ${D}/opt/${PN}
	cp -a ${S}/* .
}
