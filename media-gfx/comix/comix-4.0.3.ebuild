# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-gfx/comix/comix-4.0.3.ebuild,v 1.4 2009/05/17 16:08:26 nixnut Exp $

inherit python

DESCRIPTION="A GTK image viewer specifically designed to handle comic books."
HOMEPAGE="http://comix.sourceforge.net"
SRC_URI="mirror://sourceforge/comix/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86 ~x86-fbsd"
RDEPEND=">=dev-python/imaging-1.1.5
	>=dev-python/pygtk-2.12
	rar? ( || ( app-arch/unrar app-arch/rar ) )"
LANGS=" ca cs es fr hr hu id ja ko pl pt_BR ru sv zh_CN zh_TW"
IUSE="rar $(echo ${LANGS//\ /\ linguas_})"

src_unpack() {
	unpack ${A}
	# do not install .pyc into /usr/share
	local pythondir="$(python_get_sitedir)/comix"
	pythondir="${pythondir/\/usr\/}"
	sed -i -e "s:share/comix/src:${pythondir}:g" "${S}"/install.py || die
}

src_compile() {
	einfo "Nothing to be compiled."
}

src_install() {
	dodir /usr
	python install.py install --no-mime --dir "${D}"usr || die
	insinto /usr/share/mime/packages/
	doins "${S}"/mime/comix.xml || die
	insinto /etc/gconf/schemas/
	doins "${S}"/mime/comicbook.schemas || die
	dobin "${S}"/mime/comicthumb || die
	dodoc ChangeLog README || die

	for lang in ${LANGS} ; do
		use linguas_${lang} || rm -r "${D}"/usr/share/locale/${lang}
	done
}
