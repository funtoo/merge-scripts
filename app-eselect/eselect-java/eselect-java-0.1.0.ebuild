# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="A set of eselect modules for Java"
HOMEPAGE="http://www.gentoo.org/proj/en/java/"
SRC_URI="http://dev.gentoo.org/~sera/distfiles/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="
	!app-eselect/eselect-ecj
	!app-eselect/eselect-maven
	!<dev-java/java-config-2.2
	app-admin/eselect"

# https://bugs.gentoo.org/show_bug.cgi?id=315229
# Commented as per FL-1214:
#PDEPEND=">=virtual/jre-1.7"
