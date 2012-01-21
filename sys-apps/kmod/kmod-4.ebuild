# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit autotools

EGIT_REPO_URI="git://git.profusion.mobi/${PN}.git"

SRC_URI="http://packages.profusion.mobi/kmod/${P}.tar.xz"
KEYWORDS="~*"

DESCRIPTION="library and tools for managing linux kernel modules"
HOMEPAGE="http://git.profusion.mobi/cgit.cgi/kmod.git"

LICENSE="LGPL-2"
SLOT="0"
IUSE="-compat debug lzma static-libs -tools zlib"

REQUIRED_USE="compat? ( tools )"

DEPEND="compat? ( !!sys-apps/module-init-tools )
	lzma? ( app-arch/xz-utils )
	zlib? ( sys-libs/zlib )"
RDEPEND="${DEPEND}"

src_prepare()
{
	if [ ! -e configure ]; then
		eautoreconf || die
	else
		elibtoolize || die
	fi
}

src_configure()
{
	econf \
		$(use_enable debug) \
		$(use_with lzma xz) \
		$(use_enable static-libs static) \
		$(use_enable tools) \
		$(use_with zlib)
}

src_install()
{
	default

	# we have a .pc file for people to use
	find "${D}" -name libkmod.la -delete

	if use compat && use tools; then
	dodir /sbin
		for cmd in depmod insmod lsmod modinfo modprobe rmmod; do
			dosym /usr/bin/kmod /sbin/$cmd
		done
	fi
}
