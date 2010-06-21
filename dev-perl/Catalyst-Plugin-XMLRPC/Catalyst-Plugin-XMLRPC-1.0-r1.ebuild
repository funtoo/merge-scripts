# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=SRI
inherit perl-module

DESCRIPTION="Dispatch XMLRPC methods with Catalyst"
HOMEPAGE="http://www.cpan.org/modules/by-authors/id/S/SR/SRI/${P}.readme"

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	dev-perl/Catalyst-Runtime
	dev-perl/RPC-XML
"

src_compile() {
	export PERL_EXTUTILS_AUTOINSTALL="--skipdeps"
	perl-module_src_compile
}

