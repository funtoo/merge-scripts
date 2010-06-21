# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=ABRAXXA
inherit perl-module

DESCRIPTION="Send Email from Catalyst"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="mason netsmtp"
DEPEND="
	>=dev-perl/Catalyst-Runtime-5.7
	dev-perl/Class-C3
	>=dev-perl/Email-Send-2.185
	>=dev-perl/Email-MIME-1.859
	>=dev-perl/Email-MIME-Creator-1.453
	dev-perl/Catalyst-View-TT
	mason? ( dev-perl/Catalyst-View-Mason )
	netsmtp? (
		dev-perl/Mime-Base64
		dev-perl/Authen-SASL
	)
"

