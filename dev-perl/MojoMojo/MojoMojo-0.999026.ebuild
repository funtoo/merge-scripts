# Copyright 1999-2005 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

MODULE_AUTHOR=MRAMBERG
inherit perl-module

DESCRIPTION="iA Catalyst & DBIx::Class powered Wiki."
LICENSE="|| ( Artistic GPL-2 )"

SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND="
	>=dev-perl/Algorithm-Diff-1.1901
	>=dev-perl/Archive-Zip-1.14
	>=dev-perl/Catalyst-Runtime-0.07
	>=dev-perl/Catalyst-Action-RenderView-0.07
	>=dev-perl/Catalyst-Controller-HTML-FormFu-0.02000
	>=dev-perl/Catalyst-Model-DBIC-Schema-0.01
	dev-perl/KinoSearch
	>=dev-perl/Catalyst-Plugin-Authentication-0.10005
	>=dev-perl/Catalyst-Authentication-Store-DBIx-Class-0.101
	dev-perl/Catalyst-Plugin-Cache
	>=dev-perl/Catalyst-Plugin-ConfigLoader-0.13
	dev-perl/Catalyst-Plugin-Email
	dev-perl/Catalyst-Plugin-Session-Store-File
	dev-perl/Catalyst-Plugin-Session-State-Cookie
	>=dev-perl/Catalyst-Plugin-Singleton-0.02
	>=dev-perl/Catalyst-Plugin-Static-Simple-0.07
	>=dev-perl/Catalyst-Plugin-SubRequest-0.09
	>=dev-perl/Catalyst-Plugin-Unicode-0.8
	>=dev-perl/Catalyst-View-TT-0.23
	dev-perl/Cache
	dev-perl/config-general
	dev-perl/Data-FormValidator-Constraints-DateTime
	dev-perl/DateTime-Format-Mail
	dev-perl/DBIx-Class-DateTime-Epoch
	dev-perl/HTML-FormFu-Model-DBIC
	dev-perl/DBIx-Class-HTML-FormFu
	dev-perl/DBIx-Class-EncodedColumn
	>=dev-perl/Module-Pluggable-Ordered-1.4
	>=dev-perl/Data-Page-2.00
	>=dev-perl/DateTime-0.28
	>=dev-perl/DBD-SQLite-1.08
	>=dev-perl/File-MMagic-1.27
	dev-perl/HTML-GenToc
	>=dev-perl/HTML-Strip-1.04
	dev-perl/HTML-Scrubber
	dev-perl/HTML-TagCloud
	dev-perl/Image-ExifTool
	dev-perl/Image-Math-Constrain
	dev-perl/Imager
	dev-perl/libwww-perl
	dev-perl/Moose
	virtual/perl-Pod-Simple
	dev-perl/String-Diff
	dev-perl/Template-Plugin-JavaScript
	>=dev-perl/Text-Context-3.5
	>=dev-perl/URI-1.35
	dev-perl/XML-Clean
	>=dev-perl/yaml-0.36
	dev-perl/URI-Fetch
	dev-perl/Text-Password-Pronounceable
	>=dev-perl/DBIx-Class-0.08
	dev-perl/SQL-Translator
	>=dev-perl/Text-Markdown-1.0.17
"

