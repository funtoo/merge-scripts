# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit udev eutils git-2

DESCRIPTION="Hardware (PCI, USB, OUI, IAB) IDs databases"
HOMEPAGE="https://github.com/gentoo/hwids"
EGIT_REPO_URI="${HOMEPAGE}.git"

LICENSE="|| ( GPL-2 BSD ) public-domain"
SLOT="0"
KEYWORDS=""
IUSE="+udev"

DEPEND="udev? (
	net-misc/curl
	dev-lang/perl
	>=virtual/udev-197-r1
)"
RDEPEND="!<sys-apps/pciutils-3.1.9-r2
	!<sys-apps/usbutils-005-r1"

src_prepare() {
	emake fetch
}

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
