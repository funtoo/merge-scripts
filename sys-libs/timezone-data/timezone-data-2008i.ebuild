# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/timezone-data/timezone-data-2008i.ebuild,v 1.8 2008/12/22 04:50:25 vapier Exp $

inherit eutils toolchain-funcs flag-o-matic

code_ver=${PV%i}h
data_ver=${PV}
DESCRIPTION="Timezone data (/usr/share/zoneinfo) and utilities (tzselect/zic/zdump)"
HOMEPAGE="ftp://elsie.nci.nih.gov/pub/"
SRC_URI="ftp://elsie.nci.nih.gov/pub/tzdata${data_ver}.tar.gz
	ftp://elsie.nci.nih.gov/pub/tzcode${code_ver}.tar.gz
	mirror://gentoo/tzdata${data_ver}.tar.gz
	mirror://gentoo/tzcode${code_ver}.tar.gz"

LICENSE="BSD public-domain"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE="nls elibc_FreeBSD elibc_glibc"

DEPEND=""

S=${WORKDIR}

src_unpack() {
	unpack ${A}
	epatch "${FILESDIR}"/${PN}-2008h-makefile.patch
	tc-is-cross-compiler && cp -pR "${S}" "${S}"-native
}

src_compile() {
	local LDLIBS
	tc-export CC
	use elibc_FreeBSD && append-flags -DSTD_INSPIRED #138251
	if use nls ; then
		use elibc_glibc || LDLIBS="${LDLIBS} -lintl" #154181
		export NLS=1
	else
		export NLS=0
	fi
	# Makefile uses LBLIBS for the libs (which defaults to LDFLAGS)
	# But it also uses LFLAGS where it expects the real LDFLAGS
	emake \
		LDLIBS="${LDLIBS}" \
		|| die "emake failed"
	if tc-is-cross-compiler ; then
		emake -C "${S}"-native \
			CC=$(tc-getBUILD_CC) \
			CFLAGS="${BUILD_CFLAGS}" \
			LDFLAGS="${BUILD_LDFLAGS}" \
			LDLIBS="${LDLIBS}" \
			zic || die
	fi
}

src_install() {
	local zic=""
	tc-is-cross-compiler && zic="zic=${S}-native/zic"
	emake install ${zic} DESTDIR="${D}" || die
	rm -rf "${D}"/usr/share/zoneinfo-leaps
	dodoc README Theory
	dohtml *.htm *.jpg
}
