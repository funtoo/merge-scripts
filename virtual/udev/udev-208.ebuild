# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit multilib-build

DESCRIPTION="Virtual to select between sys-fs/udev and sys-fs/eudev"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="*"
# These default enabled IUSE flags should follow defaults of sys-fs/udev.
IUSE="+gudev introspection +kmod +hwdb +keymap selinux +static-libs"

DEPEND=""
RDEPEND="kmod? ( >=sys-fs/eudev-1.3[${MULTILIB_USEDEP},modutils,gudev?,introspection?,selinux?,static-libs?] )"
