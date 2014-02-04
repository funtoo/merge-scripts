# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils

DESCRIPTION="udev startup scripts for openrc"
HOMEPAGE="http://www.gentoo.org"

LICENSE="GPL-2"
SLOT="0"
IUSE=""
SRC_URI="http://dev.gentoo.org/~williamh/dist/${P}.tar.bz2"
KEYWORDS="*"


RESTRICT="test"

DEPEND="virtual/pkgconfig"
RDEPEND=">=virtual/udev-180
	!<sys-fs/udev-186"

src_prepare()
{
	epatch "${FILESDIR}/udev-init-openvz.patch"
	epatch_user
}

pkg_postinst()
{
	# Add udev and udev-mount to the sysinit runlevel automatically if this is
	# the first install of this package.
	if [[ -z ${REPLACING_VERSIONS} ]]
	then
		if [[ -x "${ROOT}"etc/init.d/udev \
			&& -d "${ROOT}"etc/runlevels/sysinit ]]
		then
			ln -s /etc/init.d/udev "${ROOT}"/etc/runlevels/sysinit/udev
		fi
		if [[ -x "${ROOT}"etc/init.d/udev-mount \
			&& -d "${ROOT}"etc/runlevels/sysinit ]]
		then
			ln -s /etc/init.d/udev-mount \
				"${ROOT}"etc/runlevels/sysinit/udev-mount
		fi
	fi

	# Warn the user about adding the scripts to their sysinit runlevel
	if [[ -e "${ROOT}"etc/runlevels/sysinit ]]
	then
		if [[ ! -e "${ROOT}"etc/runlevels/sysinit/udev ]]
		then
			ewarn
			ewarn "You need to add udev to the sysinit runlevel."
			ewarn "If you do not do this,"
			ewarn "your system will not be able to boot!"
			ewarn "Run this command:"
			ewarn "\trc-update add udev sysinit"
		fi
		if [[ ! -e "${ROOT}"etc/runlevels/sysinit/udev-mount ]]
		then
			ewarn
			ewarn "You need to add udev-mount to the sysinit runlevel."
			ewarn "If you do not do this,"
			ewarn "your system will not be able to boot!"
			ewarn "Run this command:"
			ewarn "\trc-update add udev-mount sysinit"
		fi
	fi

	if [[ -x $(type -P rc-update) ]] && rc-update show | grep udev-postmount | grep -qs 'boot\|default\|sysinit'; then
		ewarn "The udev-postmount service has been removed because the reasons for"
		ewarn "its existance have been removed upstream."
		ewarn "Please remove it from your runlevels."
	fi
}
