# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit multilib-build

DESCRIPTION="Virtual for libgudev providers"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0/0"
KEYWORDS="*"
IUSE="introspection +static-libs"

DEPEND=""
RDEPEND=">=sys-fs/eudev-1.5.3-r1:0/0[${MULTILIB_USEDEP},gudev,introspection?,static-libs?]"
