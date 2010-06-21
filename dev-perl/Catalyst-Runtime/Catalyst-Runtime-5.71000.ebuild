# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MRAMBERG
inherit perl-module

DESCRIPTION="The Elegant MVC Web Application Framework - runtime version"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="apache apache2 fastcgi par"
DEPEND="
	!dev-perl/Catalyst
	>=dev-perl/Module-Install-0.64
	>=dev-lang/perl-5.8.1
	dev-perl/Class-Accessor
	dev-perl/Class-Data-Inheritable
	>=dev-perl/Class-Inspector-1.06
	dev-perl/Cgi-Simple
	dev-perl/Data-Dump
	dev-perl/File-Modified
	dev-perl/HTML-Parser
	>=dev-perl/HTTP-Body-1.04
	>=dev-perl/libwww-perl-5.805
	>=dev-perl/HTTP-Request-AsCGI-0.5
	>=virtual/perl-Module-Pluggable-3.01
	>=dev-perl/Path-Class-0.09
	>=dev-perl/Text-SimpleTable-0.03
	>=dev-perl/Tree-Simple-1.15
	dev-perl/Tree-Simple-VisitorFactory
	>=dev-perl/URI-1.35
	dev-perl/MIME-Types
	apache? ( >=dev-perl/Catalyst-Engine-Apache-1.05 )
	apache2? ( >=dev-perl/Catalyst-Engine-Apache-1.05 )
	fastcgi? ( dev-perl/FCGI dev-perl/FCGI-ProcManager )
	par? ( dev-perl/PAR )
"

#src_compile() {
#	export PERL_EXTUTILS_AUTOINSTALL="--skipdeps"
#	perl-module_src_compile
#}
