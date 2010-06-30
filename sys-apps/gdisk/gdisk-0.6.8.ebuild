# Copyright 1999-2010 Funtoo Technologies, LLC 
# Copyright 2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="2"

DESCRIPTION="GPT fdisk (aka gdisk) is a text-mode partitioning tool that works on GUID Partition Table (GPT) disks"
HOMEPAGE="http://www.rodsbooks.com/gdisk/"
SRC_URI="mirror://sourceforge/gptfdisk/${P/_p/-}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"

S="${WORKDIR}/${P/_p2/}"

src_install() {
	into /
	for x in gdisk sgdisk; do
		dosbin "${x}" || die
		doman "${x}.8" || die
		dohtml "${x}.html" || die
	done
	dodoc README NEWS
}
