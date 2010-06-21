# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils

DESCRIPTION="FUSE module to mount ISO9660 images"
SRC_URI="http://ubiz.ru/dm/${P}.tar.bz2"
HOMEPAGE="http://apps.sourceforge.net/mediawiki/fuse/index.php?title=FuseIso"

LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"
IUSE=""
SLOT="0"

DEPEND=">=sys-fs/fuse-2.2.1
	>=dev-libs/glib-2.4.2"
RDEPEND=${DEPEND}

src_unpack () {
	unpack ${A}
	cd "${S}"
	# applying patch from Red Hat bug 440436
	# https://bugzilla.redhat.com/show_bug.cgi?id=440436
	EPATCH_SINGLE_MSG="Applying bug fix to access content in large ISO files"
	epatch "${FILESDIR}/${P}-largerthan4gb.patch"
}

src_install () {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog NEWS README || die "dodoc failed"
}
