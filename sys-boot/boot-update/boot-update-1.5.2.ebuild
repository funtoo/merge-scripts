# Copyright 2010 Funtoo Technologies
# Distributed under the terms of the GNU General Public License v2

EAPI="2"

DESCRIPTION="Funtoo Core Boot Framework for global boot loader configuration"
HOMEPAGE="http://www.funtoo.org/en/funtoo/core/boot"
SRC_URI="http://www.funtoo.org/archive/boot-update/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 x86"

DEPEND=""
RDEPEND="dev-lang/python >=sys-boot/grub-1.98-r2"
RESTRICT="nomirror"

src_install() {
	insinto /usr/lib/`eselect python show --python2`/site-packages
	cd ${S}/python/modules
	doins -r .

	cd ${S}

	dodoc doc/*.rst

	doman doc/boot-update.8
	doman doc/boot.conf.5

	into /
	dosbin sbin/boot-update

	dodoc etc/boot.conf.example
	insinto /etc
	doins etc/boot.conf
}

src_compile() {
	return
}
