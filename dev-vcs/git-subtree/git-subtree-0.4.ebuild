EAPI="4"

inherit eutils

DESCRIPTION="An experimental alternative to the git-submodule command. Merges and splits subtrees from your project into subprojects and back"
GITHUB_USER="apenwarr"
GITHUB_TAG="v${PV}"
HOMEPAGE="https://github.com/${GITHUB_USER}/${PN}"
SRC_URI="https://github.com/${GITHUB_USER}/${PN}/tarball/${GITHUB_TAG} -> ${P}.tar.gz"

LICENSE="AS-IS"
SLOT="0"
KEYWORDS="~*"
IUSE="doc"

RDEPEND="dev-vcs/git"

DEPEND="$RDEPEND
app-text/xmlto
app-text/asciidoc"

src_unpack() {
	unpack ${A} 
	cd "${WORKDIR}"/${GITHUB_USER}-${PN}-*
	S=$(pwd)
}

src_compile() { 
	emake doc
}

src_install() {
	exeinto /usr/bin
	newexe git-subtree.sh git-subtree || die "newexe failed"
	doman git-subtree.1
	use doc && dodoc git-subtree.txt
}
