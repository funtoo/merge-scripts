# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit versionator gnome2

DESCRIPTION="Python bindings for nautilus"
HOMEPAGE="http://svn.gnome.org/viewcvs/nautilus-python/"
SRC_URI="http://ftp.gnome.org/pub/gnome/sources/${PN}/$(get_version_component_range 1-2)/${P}.tar.bz2"
LICENSE="GPL-2"

SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""
RDEPEND=">=gnome-base/nautilus-2.6
	>=dev-python/pygtk-2.4
	>=dev-lang/python-2.3"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

