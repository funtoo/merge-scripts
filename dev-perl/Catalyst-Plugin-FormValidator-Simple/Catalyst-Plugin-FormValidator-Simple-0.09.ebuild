# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=LYOKATO
inherit perl-module

DESCRIPTION="Validator for Catalyst with FormValidator::Simple"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND=">=dev-perl/Catalyst-5.30
	>=dev-perl/FormValidator-Simple-0.13
	dev-perl/Catalyst-Plugin-FormValidator"
