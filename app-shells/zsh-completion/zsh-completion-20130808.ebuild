# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils

DESCRIPTION="Programmable Completion for zsh (includes emerge and ebuild commands)"
HOMEPAGE="http://git.overlays.gentoo.org/gitweb/?p=proj/zsh-completion.git"
SRC_URI="http://dev.gentoo.org/~radhermit/dist/${P}.tar.bz2"

LICENSE="ZSH"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=app-shells/zsh-4.3.5"

src_prepare() {
	epatch "${FILESDIR}/${PN}-eselect-20130926.patch"
}

src_install() {
	insinto /usr/share/zsh/site-functions
	doins _*

	dodoc AUTHORS
}

pkg_postinst() {
	elog
	elog "If you happen to compile your functions, you may need to delete"
	elog "~/.zcompdump{,.zwc} and recompile to make zsh-completion available"
	elog "to your shell."
	elog
}
