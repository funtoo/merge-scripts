# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-cluster/ploop/ploop-1.9.ebuild,v 1.3 2014/01/14 13:58:30 ago Exp $

EAPI=5

inherit eutils toolchain-funcs multilib systemd

DESCRIPTION="openvz tool and a library to control ploop block devices"
HOMEPAGE="http://wiki.openvz.org/Download/ploop"
SRC_URI="http://download.openvz.org/utils/ploop/${PV}/src/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="debug static-libs"

DEPEND="dev-libs/libxml2"
RDEPEND="${DEPEND}
	!<sys-cluster/vzctl-4.5
	sys-block/parted
	sys-fs/e2fsprogs
	"

DOCS=( tools/README )

src_prepare() {
	# Respect CFLAGS and CC, do not add debug by default
	sed -i \
		-e 's|CFLAGS =|CFLAGS +=|' \
		-e '/CFLAGS/s/-g -O0 //' \
		-e '/CFLAGS/s/-O2//' \
		-e 's|CC=|CC?=|' \
		-e 's/-Werror//' \
		-e '/DEBUG=yes/d' \
		-e '/LOCKDIR/s/var/run/' \
		Makefile.inc || die 'sed on Makefile.inc failed'
	# Avoid striping of binaries
	sed -e '/INSTALL/{s: -s::}' -i tools/Makefile || die 'sed on tools/Makefile failed'

	# respect AR and RANLIB, bug #452092
	tc-export AR RANLIB
	sed -i -e 's/ranlib/$(RANLIB)/' lib/Makefile || die 'sed on lib/Makefile failed'
}

src_compile() {
	emake CC="$(tc-getCC)" V=1 $(usex debug 'DEBUG' '' '=yes' '')
}

src_install() {
	default
	ldconfig -n "${D}/usr/$(get_libdir)/" || die
	use static-libs || rm "${D}/usr/$(get_libdir)/libploop.a" || die 'remove static lib failed'
}

pkg_postinst() {
	elog "Warning - API changes"
	elog "1. This version requires running vzkernel >= 2.6.32-042stab79.5 and vzctl-4.5 ot above"
	elog "2. DiskDescriptor.xml created by older ploop versions are converted to current format"
	elog "3. If you have eise --diskquota paranetr on gentoo CT, please install sys-fs/quota on CT. "
	elog "[3] is gentoo specific messages ( due stage3 not contain quta tools) "
}
