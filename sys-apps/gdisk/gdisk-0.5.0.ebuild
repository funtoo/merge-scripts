# Copyright 1999-2009 Funtoo Technologies, LLC 
# Distributed under the terms of the GNU General Public License v2

EAPI="2"

DESCRIPTION="GPT fdisk (aka gdisk) is a text-mode partitioning tool that works on GUID Partition Table (GPT) disks"
HOMEPAGE="http://www.rodsbooks.com/gdisk/"
SRC_URI="http://www.rodsbooks.com/gdisk/${P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"

src_install() {
	into /
	dosbin gdisk
}
