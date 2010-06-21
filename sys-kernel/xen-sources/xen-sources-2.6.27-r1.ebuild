# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

ETYPE="sources"
UNIPATCH_STRICTORDER="1"
K_WANT_GENPATCHES="base"
K_GENPATCHES_VER="3"
inherit kernel-2
detect_version

DESCRIPTION="Full sources for a dom0/domU Linux kernel to run under Xen"
HOMEPAGE="http://xen.org/"
IUSE=""

KEYWORDS="~x86 ~amd64"

XENPATCHES_VER="3"
XENPATCHES="xen-patches-${PV}-${XENPATCHES_VER}.tar.bz2"
XENPATCHES_URI="http://www.gentoo-quebec.org/index/Config_Mathieu/patches/${XENPATCHES}"

SRC_URI="${KERNEL_URI} ${GENPATCHES_URI} ${XENPATCHES_URI}"


UNIPATCH_LIST="${DISTDIR}/${XENPATCHES}"

DEPEND="${DEPEND} >=sys-devel/binutils-2.17"
