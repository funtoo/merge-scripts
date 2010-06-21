# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=BOBTFISH
inherit perl-module

DESCRIPTION="Authen::Htpasswd based user storage/authentication."

IUSE=""

SLOT="0"
LICENSE="|| ( Artistic GPL-2 )"
KEYWORDS="~amd64 ~x86"

DEPEND="
	>=dev-perl/Catalyst-Plugin-Authentication-0.10006
	>=dev-perl/Authen-Htpasswd-0.13
	dev-perl/Class-Accessor
	dev-perl/Crypt-PasswdMD5
"
