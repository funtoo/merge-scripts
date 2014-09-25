# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils

DESCRIPTION="Programmable Completion for Z Shell (include eselect, gcc,\
	binutils, genlop, gentoolkit, layman, openrc and portage with portage-utils completion)"

HOMEPAGE=""

SRC_URI="http://build.funtoo.org/distfiles/${P}.tar.xz
	http://ftp.osuosl.org/pub/funtoo/distfiles/${P}.tar.xz
	http://ftp.heanet.ie/mirrors/funtoo/distfiles/${P}.tar.xz"

LICENSE="ZSH"
SLOT="0"
KEYWORDS="*"

RDEPEND="app-shells/zsh"

src_prepare() {
	epatch "${FILESDIR}/${P}-eselect-funtoo.patch"
}

src_install() {
	insinto /usr/share/zsh/site-functions
	doins ${S}/_*

	dodoc AUTHORS COPYING README
}

pkg_postinst() {
	elog "If you happen to compile your functions, you may need to delete"
	elog "~/.zcompdump{,.zwc} and recompile to make zsh-completion available"
	elog "to your shell."
}
