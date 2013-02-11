# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit udev eutils

DESCRIPTION="Hardware (PCI, USB, OUI, IAB) IDs databases"
HOMEPAGE="https://github.com/gentoo/hwids"
SRC_URI="https://github.com/gentoo/hwids/archive/${P}.tar.gz"

LICENSE="|| ( GPL-2 BSD ) public-domain"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~amd64-linux ~x86-linux"
IUSE="+udev"

DEPEND="udev? ( dev-lang/perl !=sys-fs/udev-196 )"
RDEPEND="!<sys-apps/pciutils-3.1.9-r2
	!<sys-apps/usbutils-005-r1"

S=${WORKDIR}/hwids-${P}

src_compile() {
	emake UDEV=$(usex udev)
}

src_install() {
	emake UDEV=$(usex udev) install \
		DOCDIR="${EPREFIX}/usr/share/doc/${PF}" \
		MISCDIR="${EPREFIX}/usr/share/misc" \
		HWDBDIR="${EPREFIX}$(udev_get_udevdir)/hwdb.d" \
		DESTDIR="${D}"
}

pkg_postinst() {
	# until udev introduces a way to compile the database at a given
	# location, rather than just /, we can't do much on offset root.
	if [[ ${ROOT} != "" ]] && [[ ${ROOT} != "/" ]]; then
		return 0
	fi

	if use udev && [[ $(udevadm --help 2>&1) == *hwdb* ]]; then
		udevadm hwdb --update
	fi
}
