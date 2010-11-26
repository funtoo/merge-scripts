# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/sandbox/sandbox-1.2.20_alpha2-r1.ebuild,v 1.6 2009/08/13 10:49:15 vapier Exp $

#
# don't monkey with this ebuild unless contacting portage devs.
# period.
#

inherit eutils flag-o-matic toolchain-funcs multilib

PVER=

MY_P="${P/_/}"
S="${WORKDIR}/${MY_P}"
DESCRIPTION="sandbox'd LD_PRELOAD hack"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${MY_P}.tar.bz2
	http://dev.gentoo.org/~azarah/sandbox/${MY_P}.tar.bz2"
if [[ -n ${PVER} ]] ; then
	SRC_URI="${SRC_URI}
		mirror://gentoo/${MY_P}-patches-${PVER}.tar.bz2
		http://dev.gentoo.org/~azarah/sandbox/${MY_P}-patches-${PVER}.tar.bz2"
fi

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
IUSE=""

DEPEND=""

EMULTILIB_PKG="true"
has sandbox_death_notice ${EBUILD_DEATH_HOOKS} || EBUILD_DEATH_HOOKS="${EBUILD_DEATH_HOOKS} sandbox_death_notice"

sandbox_death_notice() {
	ewarn "If configure failed with a 'cannot run C compiled programs' error, try this:"
	ewarn "FEATURES=-sandbox emerge sandbox"
}

src_unpack() {
	unpack ${A}

	if [[ -n ${PVER} ]] ; then
		cd "${S}"
		epatch "${WORKDIR}/patch"
	fi

	cd "${S}"
	sed -i -e 's/&> libctest.log/>libctest.log 2>\&1/g' configure || die "sed failed" #236868

	cd "${S}/libsandbox"
	epatch "${FILESDIR}"/${PN}-1.2.18.1-open-cloexec.patch
	epatch "${FILESDIR}"/${P}-parallel.patch #190051
}

src_compile() {
	local myconf

	filter-lfs-flags #90228

	has_multilib_profile && myconf="--enable-multilib"

	local OABI=${ABI}
	for ABI in $(get_install_abis) ; do
		mkdir "${WORKDIR}/build-${ABI}"
		cd "${WORKDIR}/build-${ABI}"

		multilib_toolchain_setup ${ABI}

		# Needed for older broken portage versions (bug #109036)
		has_version '<sys-apps/portage-2.0.51.22' && \
			unset EXTRA_ECONF

		einfo "Configuring sandbox for ABI=${ABI}..."
		ECONF_SOURCE="../${MY_P}/" \
		econf ${myconf} || die
		einfo "Building sandbox for ABI=${ABI}..."
		emake || die
	done
	ABI=${OABI}
}

src_install() {
	local OABI=${ABI}
	for ABI in $(get_install_abis) ; do
		cd "${WORKDIR}/build-${ABI}"
		einfo "Installing sandbox for ABI=${ABI}..."
		emake DESTDIR="${D}" install || die "make install failed for ${ABI}"
	done
	ABI=${OABI}

	doenvd "${FILESDIR}"/09sandbox

	keepdir /var/log/sandbox
	fowners root:portage /var/log/sandbox
	fperms 0770 /var/log/sandbox

	cd "${S}"
	dodoc AUTHORS ChangeLog NEWS README
}

pkg_preinst() {
	chown root:portage "${D}"/var/log/sandbox
	chmod 0770 "${D}"/var/log/sandbox
}
