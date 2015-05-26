# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit emul-linux-x86

LICENSE="LGPL-2.1"
KEYWORDS="-* ~amd64"

DEPEND=""
RDEPEND="|| (
	>=virtual/libffi-3.0.13-r1[abi_x86_32(-)]
	~app-emulation/emul-linux-x86-baselibs-${PV}[-abi_x86_32(-)]
)"
