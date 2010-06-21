# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

MY_P="${P/_}"

inherit eutils
DESCRIPTION="GNU libmicrohttpd is a small C library that is supposed to make it easy to run an HTTP server as part of another application."
HOMEPAGE="http://www.gnu.org/software/libmicrohttpd/"
SRC_URI="ftp://ftp.gnu.org/gnu/libmicrohttpd/${MY_P}.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"

#IUSE="libgcrypt curl"
IUSE=""

#DEPEND="curl? ( net-misc/curl )
#	libgcrypt? ( dev-libs/libgcrypt )"
#RDEPEND="${DEPEND}"
DEPEND=""
RDEPEND=""

S="${WORKDIR}/${MY_P}"

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
}
