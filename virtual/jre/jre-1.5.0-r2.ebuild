# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/jre/jre-1.5.0-r2.ebuild,v 1.1 2013/06/29 10:58:57 tomwij Exp $

EAPI=4

DESCRIPTION="Virtual for Java Runtime Environment (JRE)"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="1.5"
KEYWORDS="amd64 ~arm ppc ppc64 x86 ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="|| (
		virtual/jdk:1.5
		dev-java/jamvm:0
	)"
