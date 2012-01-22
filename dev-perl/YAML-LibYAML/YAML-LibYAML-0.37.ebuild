# Copyright 2012 Funtoo Technologies
# Distributed under the terms of the GNU General Public License v2

EAPI=4

MODULE_AUTHOR=INGY
MODULE_VERSION=${PV}
inherit perl-module

DESCRIPTION="An XS Wrapper Module of libyaml"

SLOT="0"
KEYWORDS="*"

DEPEND=">=virtual/perl-Module-Build-0.28"
