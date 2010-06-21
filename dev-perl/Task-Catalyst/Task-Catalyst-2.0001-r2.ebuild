# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

DESCRIPTION="All you need to start with Catalyst"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="~amd64 ~x86"

S=${WORKDIR}

IUSE="sqlite fastcgi modperl"
DEPEND="
	>=dev-perl/Module-Install-0.64
	>=dev-perl/Catalyst-Runtime-5.7007
	>=dev-perl/Catalyst-Devel-1.02
	dev-perl/PAR
	dev-perl/Params-Validate
	>=dev-perl/Catalyst-Log-Log4perl-0.1
	dev-perl/Date-Calc
	>=dev-perl/Catalyst-Plugin-HTML-Widget-1.1
	>=dev-perl/Catalyst-Controller-FormBuilder-0.03
	>=dev-perl/Catalyst-Plugin-StackTrace-0.02
	>=dev-perl/Catalyst-Plugin-Prototype-1.32
	>=dev-perl/Catalyst-Plugin-Session-0.05
	>=dev-perl/Catalyst-Plugin-Session-Store-File-0.07
	>=dev-perl/Catalyst-Plugin-Session-State-Cookie-0.02
	>=dev-perl/Catalyst-Plugin-Session-State-URI-0.02
	>=dev-perl/Catalyst-Plugin-Authentication-0.05
	dev-perl/Catalyst-Authentication-Store-DBIx-Class
	!dev-perl/Catalyst-Plugin-Authentication-Store-DBIx-Class
	!dev-perl/Catalyst-Plugin-Authentication-Store-DBIC
	>=dev-perl/Catalyst-Plugin-Authentication-Store-Htpasswd-0.02
	>=dev-perl/Catalyst-Plugin-Authorization-ACL-0.06
	>=dev-perl/Catalyst-Plugin-Authorization-Roles-0.03
	>=dev-perl/Catalyst-Plugin-I18N-0.05
	>=dev-perl/Catalyst-Controller-BindLex-0.03
	>=dev-perl/Catalyst-Model-DBIC-Schema-0.08
	>=dev-perl/Catalyst-View-TT-0.22
	>=dev-perl/Test-WWW-Mechanize-Catalyst-0.35
	fastcgi? ( dev-perl/FCGI dev-perl/FCGI-ProcManager )
	sqlite? ( dev-perl/DBD-SQLite )
	modperl? ( >=dev-perl/Catalyst-Engine-Apache-1.05 )
"
