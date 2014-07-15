# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="Virtual for IO"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="~*"
IUSE=""

DEPEND=""
RDEPEND="
	|| ( =dev-lang/perl-5.18* ~perl-core/${PN#perl-}-${PV} )
	!>perl-core/${PN#perl-}-${PV}-r999"
