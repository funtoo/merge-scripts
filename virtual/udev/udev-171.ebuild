# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/udev/udev-171.ebuild,v 1.5 2012/12/12 15:32:42 axs Exp $

EAPI=2

DESCRIPTION="Virtual for udev implementation and number of its features"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="*"
IUSE="+gudev +hwdb introspection keymap selinux static-libs"

DEPEND=""
RDEPEND="|| ( ~sys-fs/udev-171[gudev?,hwdb?,introspection?,keymap?,selinux?]
	~sys-fs/eudev-0[gudev?,hwdb?,introspection?,keymap?,selinux?] )"
