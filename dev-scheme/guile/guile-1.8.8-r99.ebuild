# Distributed under the terms of the GNU General Public License v2

EAPI="5"

DESCRIPTION="Scheme interpreter"
HOMEPAGE="http://www.gnu.org/software/guile/"

LICENSE="metapackage"
SLOT="12"
KEYWORDS="*"
IUSE="debug debug-freelist debug-malloc +deprecated discouraged emacs networking nls +regex +threads"
DEPEND="dev-scheme/guile:0/1.8.8[debug?,debug-freelist?,debug-malloc?,deprecated?,discouraged?,emacs?,networking?,nls?,regex?,threads?]"
RDEPEND="${DEPEND}"
