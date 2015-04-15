# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="General purpose crypto library based on the code used in GnuPG"
HOMEPAGE="http://www.gnupg.org/"

LICENSE="LGPL-2.1 MIT"
SLOT="11/11" # subslot = soname major version
KEYWORDS="*"
IUSE="abi_x86_32"

RDEPEND="=dev-libs/libgcrypt-compat-$PV*[abi_x86_32=]"
