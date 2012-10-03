# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/gvfs/gvfs-1.12.3-r1.ebuild,v 1.1 2012/09/26 10:54:41 ssuominen Exp $

EAPI=4
GCONF_DEBUG=no
GNOME2_LA_PUNT=yes

inherit autotools bash-completion-r1 eutils gnome2

[[ ${PV} = 9999 ]] && inherit gnome2-live

DESCRIPTION="GNOME Virtual Filesystem Layer"
HOMEPAGE="http://www.gnome.org"

LICENSE="LGPL-2+"
SLOT="0"

if [[ ${PV} = 9999 ]]; then
	KEYWORDS=""
	DOCS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~sparc-solaris ~x86-solaris"
	DOCS="AUTHORS ChangeLog NEWS MAINTAINERS README TODO" # ChangeLog.pre-1.2 README.commits
fi

SRC_URI="${SRC_URI}
	http://dev.gentoo.org/~tetromino/distfiles/aclocal/libgcrypt.m4.bz2"

IUSE="afp archive avahi bluetooth bluray cdda doc fuse gdu gnome-keyring gphoto2 +http ios samba +udev udisks"

RDEPEND=">=dev-libs/glib-2.31.0:2
	sys-apps/dbus
	dev-libs/libxml2
	net-misc/openssh
	afp? ( >=dev-libs/libgcrypt-1.2.2 )
	archive? ( app-arch/libarchive )
	avahi? ( >=net-dns/avahi-0.6 )
	bluetooth? (
		>=app-mobilephone/obex-data-server-0.4.5
		dev-libs/dbus-glib
		net-wireless/bluez
		dev-libs/expat )
	bluray? ( media-libs/libbluray )
	fuse? ( >=sys-fs/fuse-2.8.0 )
	gdu? ( || (
		>=gnome-base/libgdu-3.0.2
		=sys-apps/gnome-disk-utility-3.0.2-r300
		=sys-apps/gnome-disk-utility-3.0.2-r200 ) )
	gnome-keyring? ( >=gnome-base/gnome-keyring-1.0 )
	gphoto2? ( >=media-libs/libgphoto2-2.4.7 )
	ios? (
		>=app-pda/libimobiledevice-1.1.0
		>=app-pda/libplist-1 )
	udev? (
		cdda? ( >=dev-libs/libcdio-0.78.2[-minimal] )
		|| ( >=sys-fs/udev-171[gudev] >=sys-fs/udev-164-r2[extras] ) )
	udisks? ( =sys-fs/udisks-1.0.4-r2 )
	http? ( >=net-libs/libsoup-gnome-2.26.0 )
	samba? ( >=net-fs/samba-3.4.6[smbclient] )"
DEPEND="${RDEPEND}
	>=dev-util/intltool-0.40
	virtual/pkgconfig
	dev-util/gtk-doc-am
	doc? ( >=dev-util/gtk-doc-1 )"

REQUIRED_USE="cdda? ( udev )"

pkg_setup() {
	G2CONF="${G2CONF}
		--disable-bash-completion
		--disable-hal
		--disable-schemas-compile
		--with-dbus-service-dir="${EPREFIX}"/usr/share/dbus-1/services
		$(use_enable afp)
		$(use_enable archive)
		$(use_enable avahi)
		$(use_enable bluetooth obexftp)
		$(use_enable bluray)
		$(use_enable cdda)
		$(use_enable fuse)
		$(use_enable gdu)
		$(use_enable gphoto2)
		$(use_enable ios afc)
		$(use_enable udev)
		$(use_enable udev gudev)
		$(use_enable http)
		$(use_enable gnome-keyring keyring)
		$(use_enable samba)
		$(use_enable udisks)"
}

src_prepare() {
	# Conditional patching purely to avoid eautoreconf
	if use gphoto2; then
		epatch "${FILESDIR}"/${PN}-1.12.3-gphoto2-stricter-checks.patch
		epatch "${FILESDIR}"/${PN}-1.12.3-gphoto2-2.5-{1,2}.patch
	fi

	if use archive; then
		epatch "${FILESDIR}"/${PN}-1.2.2-expose-archive-backend.patch
		echo mount-archive.desktop.in >> po/POTFILES.in
		echo mount-archive.desktop.in.in >> po/POTFILES.in
	fi

	if ! use udev; then
		sed -i -e 's/gvfsd-burn/ /' daemon/Makefile.am || die
		sed -i -e 's/burn.mount.in/ /' daemon/Makefile.am || die
		sed -i -e 's/burn.mount/ /' daemon/Makefile.am || die
	fi

	if use gphoto2 || use archive || ! use udev; then
		# libgcrypt.m4 needed for eautoreconf, bug #399043
		mv "${WORKDIR}/libgcrypt.m4" "${S}"/ || die

		AT_M4DIR=. eautoreconf
	fi

	gnome2_src_prepare
}

src_install() {
	gnome2_src_install
	newbashcomp programs/gvfs-bash-completion.sh ${PN}
}
