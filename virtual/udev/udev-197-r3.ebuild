# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="Virtual to select between sys-fs/udev and sys-fs/eudev"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="*"
# These default enabled IUSE flags should follow defaults of sys-fs/udev.
IUSE="gudev hwdb introspection keymap +kmod selinux static-libs"

DEPEND=""
RDEPEND=">=sys-fs/udev-197-r8[gudev?,hwdb?,introspection?,keymap?,kmod?,selinux?,static-libs?]" 

