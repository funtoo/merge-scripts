# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit toolchain-funcs git

DESCRIPTION="An AudioScrobbler client for MPD written in C++"
HOMEPAGE="http://50hz.ws/mpdas/"
EGIT_REPO_URI="git://github.com/hrkfrd/mpdas.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
IUSE=""

RDEPEND="media-libs/libmpd
	net-misc/curl"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_compile() {
	tc-export CXX
	emake CONFIG="/etc" || die "emake failed."
}

src_install() {
	dobin ${PN} || die "dobin failed."
	doman ${PN}.1
	dodoc ChangeLog mpdasrc.example README
}

pkg_postinst() {
	elog "For further configuration help consult the README in"
	elog "/usr/share/doc/${PF}."
}
