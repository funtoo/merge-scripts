# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2

WXWRAP_VER=1.3
WXESELECT_VER=1.4

DESCRIPTION="Eselect module and wrappers for wxWidgets"
HOMEPAGE="http://www.gentoo.org"
SRC_URI="mirror://gentoo/wxwidgets.eselect-${WXESELECT_VER}.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="+symlink"

DEPEND="!<=x11-libs/wxGTK-2.6.4.0-r2"
RDEPEND=">=app-admin/eselect-1.2.3"

S=${WORKDIR}

src_install() {
	insinto /usr/share/eselect/modules
	newins "${S}"/wxwidgets.eselect-${WXESELECT_VER} wxwidgets.eselect \
		|| die "Failed installing module"

	insinto /usr/share/aclocal
	newins "${FILESDIR}"/wxwin.m4-2.9 wxwin.m4 || die "Failed installing m4"

	newbin "${FILESDIR}"/wx-config-${WXWRAP_VER} wx-config \
		|| die "Failed installing wx-config"
	newbin "${FILESDIR}"/wxrc-${WXWRAP_VER} wxrc \
		|| die "Failed installing wxrc"

	keepdir /var/lib/wxwidgets
	keepdir /usr/share/bakefile/presets
}


pkg_postinst() {
	if use symlink ; then
		if [[ -e "${ROOT}"/usr/lib/wx/config ]] ; then
			local wxwidgets=( $(find -H "${ROOT}"/usr/lib/wx/config/* -printf "%f " 2> /dev/null) )
			if [[ ! -z "${wxwidgets[@]}" && "${#wxwidgets[@]}" == 1 ]] ; then
				eselect wxwidgets set  "${wxwidgets[0]}"
				echo
				elog "Portage detected that your system has only one wxWidgets profile."
				elog "Your systems wxWidgets profile is now set to ${wxwidgets[0]}"
				echo
			fi
		fi
	fi
}
