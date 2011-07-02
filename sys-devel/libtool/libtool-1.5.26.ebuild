# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/libtool/libtool-1.5.26.ebuild,v 1.11 2010/09/26 21:23:14 ssuominen Exp $

inherit eutils

DESCRIPTION="A shared library tool for developers"
HOMEPAGE="http://www.gnu.org/software/libtool/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="1.5"
# Keep around for a bit in case someone really needs libtool-1.x
#KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE="vanilla"

RDEPEND="sys-devel/gnuconfig
	>=sys-devel/autoconf-2.60
	>=sys-devel/automake-1.10"
DEPEND="${RDEPEND}
	sys-apps/help2man"

gen_ltmain_sh() {
	local date=
	local PACKAGE=
	local VERSION=

	rm -f ltmain.shT
	date=`./mkstamp < ./ChangeLog` && \
	eval `egrep '^[[:space:]]*PACKAGE.*=' configure` && \
	eval `egrep '^[[:space:]]*VERSION.*=' configure` && \
	sed -e "s/@PACKAGE@/${PACKAGE}/" -e "s/@VERSION@/${VERSION}/" \
		-e "s%@TIMESTAMP@%$date%" ./ltmain.in > ltmain.shT || return 1

	mv -f ltmain.shT ltmain.sh || {
		(rm -f ltmain.sh && cp ltmain.shT ltmain.sh && rm -f ltmain.shT)
		return 1
	}

	return 0
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	use vanilla && return 0

	# Make sure non of the patches touch ltmain.sh, but rather ltmain.in
	rm -f ltmain.sh*

	epatch "${FILESDIR}"/1.5.20/${PN}-1.5.20-use-linux-version-in-fbsd.patch #109105
	epatch "${FILESDIR}"/1.5.10/libtool-1.5.10-locking.patch #40992

	# Note: The following patches should be dropped with libtool-2+
	epatch "${FILESDIR}"/1.5.20/${PN}-1.5.20-version-checking.patch #73140
	sed -i "s:@_LT_VERSION@:${PV}:" libtool.m4 || die "sed libtool.m4"
	epatch "${FILESDIR}"/1.5.6/libtool-1.5-filter-host-tags.patch
	epatch "${FILESDIR}"/1.5.20/libtool-1.5.20-override-LD_LIBRARY_PATH.patch

	ebegin "Generating ltmain.sh"
	gen_ltmain_sh || die "Failed to generate ltmain.sh!"
	eend 0

	# Now let's run all our autotool stuff so that files we patch
	# below don't get regenerated on us later
	einfo "Ignore any warnings below about QA/autotools"
	cp libtool.m4 acinclude.m4
	local d p
	for d in . libltdl ; do
		ebegin "Running autotools in '${d}'"
		cd "${S}"/${d}
		touch acinclude.m4
		for p in aclocal "automake -c -a" autoconf ; do
			${p} || die "${p}"
		done
		eend 0
	done
	cd "${S}"

	epunt_cxx
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog* NEWS README THANKS TODO doc/PLATFORMS

	local x
	for x in libtool libtoolize ; do
		help2man ${x} > ${x}.1
		doman ${x}.1 || die
	done

	for x in $(find "${D}" -name config.guess -o -name config.sub) ; do
		rm -f "${x}" ; ln -sf ../gnuconfig/$(basename "${x}") "${x}"
	done
	cd "${D}"/usr/share/libtool/libltdl
	for x in config.guess config.sub ; do
		rm -f ${x} ; ln -sfn ../${x} ${x}
	done
}
