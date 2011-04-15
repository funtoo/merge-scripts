# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/gptfdisk/gptfdisk-0.6.13.ebuild,v 1.1 2011/04/02 10:52:44 alexxy Exp $

EAPI="2"

MY_PN="gdisk"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="GPT fdisk is a text-mode partitioning tool that works on GUID Partition Table (GPT) disks"
HOMEPAGE="http://www.rodsbooks.com/gdisk/"
SRC_URI="mirror://sourceforge/gptfdisk/${MY_P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86 sparc"

DEPEND=">=dev-libs/icu-4.6"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"

src_install() {
	into / 
	for x in gdisk sgdisk; do
		dosbin "${x}" || die
		doman "${x}.8" || die
		dohtml "${x}.html" || die
	done
	dodoc README NEWS
}
