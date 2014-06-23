# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit multilib-build

DESCRIPTION="Virtual to select between different udev daemon providers"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="*"
# These default enabled IUSE flags should follow defaults of sys-fs/udev.
IUSE="+gudev +hwdb introspection +static-libs"

DEPEND=""
RDEPEND="virtual/libudev:0/1[${MULTILIB_USEDEP},static-libs?]
	gudev? ( virtual/libgudev:0/0[${MULTILIB_USEDEP},introspection?,static-libs?] )"
