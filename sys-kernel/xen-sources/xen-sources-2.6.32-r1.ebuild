# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/xen-sources/xen-sources-2.6.32-r1.ebuild,v 1.1 2010/04/07 17:15:27 patrick Exp $

ETYPE="sources"
UNIPATCH_STRICTORDER="1"
K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="9"
inherit kernel-2
detect_version

DESCRIPTION="Full sources for a dom0/domU Linux kernel to run under Xen"
HOMEPAGE="http://xen.org/"
IUSE=""

KEYWORDS="~x86 ~amd64"

XENPATCHES_VER="1"
XENPATCHES="xen-patches-${PV}-${XENPATCHES_VER}.tar.bz2"
XENPATCHES_URI="http://gentoo-xen-kernel.googlecode.com/files/${XENPATCHES}"

SRC_URI="${KERNEL_URI} ${GENPATCHES_URI} ${XENPATCHES_URI}"

UNIPATCH_LIST="${DISTDIR}/${XENPATCHES}"

DEPEND="${DEPEND} >=sys-devel/binutils-2.17"
