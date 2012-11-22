# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-fs/udisks/udisks-1.0.4-r2.ebuild,v 1.13 2012/07/29 18:28:09 armin76 Exp $

EAPI=4
inherit eutils bash-completion-r1 linux-info

DESCRIPTION="Daemon providing interfaces to work with storage devices"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/udisks"
SRC_URI="http://hal.freedesktop.org/releases/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm ia64 ~mips ppc ppc64 sh sparc x86"
IUSE="debug nls remote-access"

COMMON_DEPEND=">=dev-libs/dbus-glib-0.98
	>=dev-libs/glib-2.28
	>=dev-libs/libatasmart-0.18
	>=sys-auth/polkit-0.104-r1
	>=sys-apps/dbus-1.4.20
	>=sys-apps/sg3_utils-1.27.20090411
	>=sys-block/parted-3
	|| ( >=sys-fs/udev-171-r5[gudev,hwdb] <sys-fs/udev-171[extras] )
	>=sys-fs/lvm2-2.02.66"
# util-linux -> mount, umount, swapon, swapoff (see also #403073)
RDEPEND="${COMMON_DEPEND}
	>=sys-apps/util-linux-2.20.1-r2
	virtual/eject
	remote-access? ( net-dns/avahi )"
DEPEND="${COMMON_DEPEND}
	app-text/docbook-xsl-stylesheets
	dev-libs/libxslt
	dev-util/intltool
	virtual/pkgconfig"

pkg_setup() {
	# Listing only major arch's here to avoid tracking kernel's defconfig
	if use amd64 || use arm || use ppc || use ppc64 || use x86; then
		CONFIG_CHECK="~!IDE" #319829
		CONFIG_CHECK+=" ~USB_SUSPEND" #331065
		CONFIG_CHECK+=" ~NLS_UTF8" #425562
		linux-info_pkg_setup
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.0.2-ntfs-3g.patch
}

src_configure() {
	# device-mapper -> lvm2 -> mandatory depend -> force enabled
	econf \
		--localstatedir="${EPREFIX}"/var \
		--disable-static \
		$(use_enable debug verbose-mode) \
		--enable-man-pages \
		--disable-gtk-doc \
		--enable-lvm2 \
		--enable-dmmp \
		$(use_enable remote-access) \
		$(use_enable nls) \
		--with-html-dir="${EPREFIX}"/deprecated
}

src_test() {
	ewarn "Skipping testsuite because sys-fs/udisks:0 is deprecated"
	ewarn "in favour of sys-fs/udisks:2."
}

src_install() {
	emake DESTDIR="${D}" slashsbindir=/usr/sbin install #398081
	dodoc AUTHORS HACKING NEWS README

	rm -f "${ED}"/etc/profile.d/udisks-bash-completion.sh
	newbashcomp tools/udisks-bash-completion.sh ${PN}

	find "${ED}" -name '*.la' -exec rm -f {} +

	keepdir /media
	keepdir /var/lib/udisks #383091

	rm -rf "${ED}"/deprecated
}
