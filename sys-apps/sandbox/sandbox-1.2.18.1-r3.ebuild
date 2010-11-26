# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/sandbox/sandbox-1.2.18.1-r3.ebuild,v 1.3 2009/08/13 10:49:15 vapier Exp $

#
# don't monkey with this ebuild unless contacting portage devs.
# period.
#

inherit eutils flag-o-matic toolchain-funcs multilib

DESCRIPTION="sandbox'd LD_PRELOAD hack"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2
	http://dev.gentoo.org/~azarah/sandbox/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
IUSE=""

DEPEND=""

EMULTILIB_PKG="true"

setup_multilib() {
	if use amd64 && has_m32 && [[ ${CONF_MULTILIBDIR} == "lib32" ]]; then
		export DEFAULT_ABI="amd64"
		export MULTILIB_ABIS="x86 amd64"
		export CFLAGS_amd64=${CFLAGS_amd64:-"-m64"}
		export CFLAGS_x86=${CFLAGS_x86-"-m32 -L/emul/linux/x86/lib -L/emul/linux/x86/usr/lib"}
		export CHOST_amd64="x86_64-pc-linux-gnu"
		export CHOST_x86="i686-pc-linux-gnu"
		export LIBDIR_amd64=${LIBDIR_amd64-${CONF_LIBDIR}}
		export LIBDIR_x86=${LIBDIR_x86-${CONF_MULTILIBDIR}}
	fi
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-open-normal-fail.patch #135745
	epatch "${FILESDIR}"/${P}-open-cloexec.patch #196720
	epatch "${FILESDIR}"/${P}-rtld-validation.patch #206678
	sed -i -e 's/&> libctest.log/>libctest.log 2>\&1/g' configure || die "sed failed" #236868
}

abi_fail_check() {
	local ABI=$1
	if [[ ${ABI} == "x86" ]] ; then
		echo
		eerror "Building failed for ABI=x86!.  This usually means a broken"
		eerror "multilib setup.  Please fix that before filling a bugreport"
		eerror "against sandbox."
		echo
	fi
}

src_compile() {
	local myconf
	local iscross=0

	setup_multilib

	filter-lfs-flags #90228

	has_multilib_profile && myconf="--enable-multilib"

	ewarn "If configure fails with a 'cannot run C compiled programs' error, try this:"
	ewarn "FEATURES=-sandbox emerge sandbox"

	[[ -n ${CBUILD} && ${CBUILD} != ${CHOST} ]] && iscross=1

	OABI=${ABI}
	OCHOST=${CHOST}
	for ABI in $(get_install_abis); do
		mkdir "${WORKDIR}/build-${ABI}-${OCHOST}"
		cd "${WORKDIR}/build-${ABI}-${OCHOST}"

		# Needed for older broken portage versions (bug #109036)
		has_version '<sys-apps/portage-2.0.51.22' && \
			unset EXTRA_ECONF

		export ABI
		export CHOST=$(get_abi_CHOST)
		[[ ${iscross} == 0 ]] && export CBUILD=${CHOST}

		einfo "Configuring sandbox for ABI=${ABI}..."
		ECONF_SOURCE="../${P}/" \
		econf --libdir="/usr/$(get_libdir)" ${myconf}
		einfo "Building sandbox for ABI=${ABI}..."
		emake || {
			abi_fail_check "${ABI}"
			die "emake failed for ${ABI}"
		}
	done
	ABI=${OABI}
	CHOST=${OCHOST}
}

src_install() {
	setup_multilib

	OABI=${ABI}
	for ABI in $(get_install_abis); do
		cd "${WORKDIR}/build-${ABI}-${CHOST}"
		einfo "Installing sandbox for ABI=${ABI}..."
		make DESTDIR="${D}" install || die "make install failed for ${ABI}"
	done
	ABI=${OABI}

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
