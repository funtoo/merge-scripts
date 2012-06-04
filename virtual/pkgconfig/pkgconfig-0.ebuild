# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/pkgconfig/pkgconfig-0.ebuild,v 1.8 2012/05/28 22:26:49 ryao Exp $

EAPI=2

DESCRIPTION="Virtual for the pkg-config implementation"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="
	|| ( dev-util/pkgconf[pkg-config]
		>=dev-util/pkgconfig-0.26
		dev-util/pkg-config-lite
		dev-util/pkgconfig-openbsd[pkg-config]
	)"
RDEPEND="${DEPEND}"
