# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/Module-Starter/Module-Starter-1.54.ebuild,v 1.1 2010/02/15 12:53:56 tove Exp $

EAPI=2

MODULE_AUTHOR=PETDANCE
inherit perl-module

DESCRIPTION="A simple starter kit for any module"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"

RDEPEND="
	virtual/perl-File-Spec
	virtual/perl-Getopt-Long
	>=virtual/perl-PodParser-1.21
"
DEPEND="${RDEPEND}
	test? (
		virtual/perl-Test-Simple
		>=virtual/perl-Test-Harness-0.21
	)
"

SRC_TEST=do
