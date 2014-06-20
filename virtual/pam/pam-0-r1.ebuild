# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/pam/pam-0-r1.ebuild,v 1.2 2014/06/18 20:57:29 mgorny Exp $

EAPI=5

inherit multilib-build

DESCRIPTION="Virtual for PAM (Pluggable Authentication Modules)"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND=""
RDEPEND="
	|| (
		>=sys-libs/pam-1.1.6-r2[${MULTILIB_USEDEP}]
		>=sys-auth/openpam-20120526-r1[${MULTILIB_USEDEP}]
	)"
