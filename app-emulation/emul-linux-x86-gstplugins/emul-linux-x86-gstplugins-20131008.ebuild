# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit emul-linux-x86

LICENSE="GPL-2 LGPL-2 LGPL-2.1"
KEYWORDS="-* amd64"

DEPEND=""
RDEPEND="~app-emulation/emul-linux-x86-baselibs-${PV}
	~app-emulation/emul-linux-x86-db-${PV}
	~app-emulation/emul-linux-x86-gtklibs-${PV}
	~app-emulation/emul-linux-x86-medialibs-${PV}
	~app-emulation/emul-linux-x86-soundlibs-${PV}"
