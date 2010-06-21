# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=CFRANKS
inherit perl-module

DESCRIPTION="HTML Form Creation, Rendering and Validation Framework"
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/Captcha-reCAPTCHA-0.92
	dev-perl/Class-Accessor-Chained
	dev-perl/Class-C3
	>=dev-perl/Config-Any-0.10
	dev-perl/crypt-cbc
	dev-perl/Crypt-DES
	dev-perl/Data-Visitor
	dev-perl/Date-Calc
	>=dev-perl/DateTime-0.38
	>=dev-perl/DateTime-Format-Builder-0.7901
	dev-perl/DateTime-Format-Natural
	dev-perl/DateTime-Format-Strptime
	dev-perl/DateTime-Locale
	dev-perl/Email-Valid
	dev-perl/File-ShareDir
	dev-perl/HTML-Scrubber
	dev-perl/HTML-TokeParser-Simple
	dev-perl/libwww-perl
	dev-perl/List-MoreUtils
	virtual/perl-Locale-Maketext-Simple
	virtual/perl-Module-Pluggable
	dev-perl/Readonly
	dev-perl/Regexp-Copy
	dev-perl/regexp-common
	dev-perl/Task-Weaken
	>=dev-perl/YAML-Syck-1.04
	dev-perl/Template-Toolkit
"

