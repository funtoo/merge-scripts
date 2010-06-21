# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=YANNK
inherit perl-module

DESCRIPTION="Make forward() to throw exception"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/Module-Install
	dev-perl/Catalyst-Runtime
"

src_compile() {
	export PERL_EXTUTILS_AUTOINSTALL="--skipdeps"
	perl-module_src_compile
}
