# Copyright 2003-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-misc/ignuit/ignuit-0.0.13.ebuild,v 1.2 2009/04/13 00:13:56 ken69267 Exp $

DESCRIPTION="memorization aid based on the Leitner flashcard system"
HOMEPAGE="http://homepages.ihug.co.nz/~trmusson/programs.html#ignuit"
SRC_URI="http://homepages.ihug.co.nz/~trmusson/stuff/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="examples"

RDEPEND=">=gnome-base/libgnomeui-2.22.1
	gnome-base/gconf
	gnome-base/libglade
	>=dev-libs/glib-2
	>=x11-libs/gtk+-2
	>=media-libs/gstreamer-0.10.20
	dev-libs/libxslt
	dev-libs/libxml2
	x11-libs/pango
	app-text/dvipng
	virtual/latex-base"

DEPEND="${RDEPEND}
	sys-devel/gettext
	dev-util/intltool"

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed."
	dodoc AUTHORS NEWS README TODO || die "dodoc failed"

	if use examples; then
		insinto /usr/share/doc/${PF}
		doins -r examples
	fi
}
