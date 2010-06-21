# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/gimmix/gimmix-0.5.6.1.ebuild,v 1.6 2009/05/22 11:58:31 ssuominen Exp $

EAPI=2

DESCRIPTION="a graphical music player daemon (MPD) client using GTK+2"
HOMEPAGE="http://gimmix.berlios.de/"
SRC_URI="mirror://berlios/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~ppc ~sparc x86"
IUSE="cover lyrics taglib"

RDEPEND=">=media-libs/libmpd-0.17
	gnome-base/libglade
	x11-libs/gtk+:2
	cover? ( net-libs/libnxml net-misc/curl )
	lyrics? ( net-libs/libnxml net-misc/curl )
	taglib? ( >=media-libs/taglib-1.5 )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	dev-util/intltool"

src_configure() {
	econf \
		$(use_enable cover) \
		$(use_enable lyrics) \
		$(use_enable taglib tageditor)
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog README TODO
}
