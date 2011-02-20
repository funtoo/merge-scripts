# Copyright 2011 Funtoo Technologies 
# Distributed under the terms of the GNU General Public License v2

EAPI=2
ETYPE="sources"

KV_DEB=30
KV_FULL=debian-${PVR}
EXTRAVERSION=debian-${KV_DEB}

inherit kernel-2
detect_version

KEYWORDS="amd64 x86"
DESCRIPTION="Debian Sources - with optional OpenVZ support"
HOMEPAGE="http://www.debian.org"
SRC_URI="
	 http://ftp.de.debian.org/debian/pool/main/l/linux-2.6/linux-2.6_2.6.32.orig.tar.gz
	 http://ftp.de.debian.org/debian/pool/main/l/linux-2.6/linux-2.6_2.6.32-30.diff.gz"
UNIPATCH_STRICTORDER=1
UNIPATCH_LIST="${FILESDIR}/debian-sources-2.6.32.30-bridgemac.patch"
IUSE="openvz"
K_EXTRAEINFO=""

src_unpack() {
	cd ${WORKDIR}
	unpack linux-2.6_2.6.32.orig.tar.gz
	cat ${DISTDIR}/linux-2.6_2.6.32-30.diff.gz | gzip -d | patch -p1 || die
	mv linux-* linux-${KV_FULL} || die
	mv debian linux-${KV_FULL}/ || die
	cd ${S}
	sed -i \
		-e 's/^sys.path.append.*$/sys.path.append(".\/debian\/lib\/python")/' \
		-e 's/^_default_home =.*$/_default_home = ".\/debian\/patches"/' \
		debian/bin/patch.apply || die
	python2 debian/bin/patch.apply $KV_DEB || die
	if use openvz
	then
		python2 debian/bin/patch.apply -a $ARCH -f openvz || die
	fi
	#unipatch "${UNIPATCH_LIST}"
	unpack_set_extraversion
	# working on config extraction:
	#sed -ne "/^binary-arch_.*::\$/ { s/^binary-arch_\(.*\)::\$/\[\1\]\n/;N;s/[[:space:]]*\\\$(MAKE) -f debian\/rules.real \([a-z-]*\)[[:space:]]*/\n\nKIND \1\n\n/;s/[[:space:]]\([A-Z_]*\)='\([^']*\)'/\1 \2\n/g;p }" rules.gen
}

pkg_postinst() {
	kernel-2_pkg_postinst
}
