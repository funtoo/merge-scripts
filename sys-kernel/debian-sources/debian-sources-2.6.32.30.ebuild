# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/openvz-sources/openvz-sources-2.6.18.028.066.7.ebuild,v 1.1 2009/11/26 19:12:49 pva Exp $

EAPI=2
ETYPE="sources"

KV_FULL=${PN}-${PVR}
EXTRAVERSION=30

inherit kernel-2
detect_version

KEYWORDS="~amd64 ~x86"
IUSE=""
DESCRIPTION="Full Linux kernel sources - RHEL5 kernel with OpenVZ patchset"
HOMEPAGE="http://www.openvz.org"
SRC_URI="
	 http://ftp.de.debian.org/debian/pool/main/l/linux-2.6/linux-2.6_2.6.32.orig.tar.gz
	 http://ftp.de.debian.org/debian/pool/main/l/linux-2.6/linux-2.6_2.6.32-30.diff.gz"

UNIPATCH_STRICTORDER=1
UNIPATCH_LIST="${FILESDIR}/debian-sources-2.6.32.30-bridgemac.patch"

K_EXTRAEINFO=""

src_unpack() {
	cd ${WORKDIR}
	unpack linux-2.6_2.6.32.orig.tar.gz
	cat ${DISTDIR}/linux-2.6_2.6.32-30.diff.gz | gzip -d | patch -p1 || die
	mv linux-* linux-${KV_FULL} || die
	mv debian linux-${KV_FULL}/ || die
	cd ${S}
	unipatch "${UNIPATCH_LIST}"
}

pkg_postinst() {
	kernel-2_pkg_postinst
}
