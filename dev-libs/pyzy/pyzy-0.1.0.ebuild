# Copyright (c) 2013 Funtoo Linux. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="4"
inherit eutils

DESCRIPTION="The Chinese PinYin and Bopomofo conversion library."
HOMEPAGE="http://code.google.com/p/pyzy/"

SRC_URI="http://pyzy.googlecode.com/files/pyzy-${PV}.tar.gz
	http://pyzy.googlecode.com/files/pyzy-database-1.0.0.tar.bz2"
LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="amd64 x86 arm"
IUSE=""
RDEPEND=">=dev-db/sqlite-3.6.18
	>=dev-libs/glib-2.24"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	>=sys-devel/gettext-0.16.1"

src_unpack() {
	unpack pyzy-${PV}.tar.gz
}

src_prepare() {
	# Using open-phrase database downloaded by this ebuild script.
	epatch "${FILESDIR}"/pyzy-dont-download-dictionary-file.patch || die
}

src_configure() {
	econf --enable-db-open-phrase --disable-db-android || die "configure failed"
}
