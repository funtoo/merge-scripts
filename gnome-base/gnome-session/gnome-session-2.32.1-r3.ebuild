# Distributed under the terms of the GNU General Public License v2

EAPI="4"
GCONF_DEBUG="yes"
GNOME_TARBALL_SUFFIX="bz2"

inherit autotools eutils gnome2

DESCRIPTION="Gnome session manager"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2 LGPL-2 FDL-1.1"
SLOT="0"
KEYWORDS="*"

IUSE="doc ipv6 elibc_FreeBSD"

# x11-misc/xdg-user-dirs{,-gtk} are needed to create the various XDG_*_DIRs, and
# create .config/user-dirs.dirs which is read by glib to get G_USER_DIRECTORY_*
# xdg-user-dirs-update is run during login (see 10-user-dirs-update-gnome below).
# >=gconf-3.2.6 no longer provides gconf-sanity-check-2
RDEPEND=">=dev-libs/glib-2.16:2
	>=x11-libs/gtk+-2.22.0:2
	>=dev-libs/dbus-glib-0.76
	>=gnome-base/gconf-2:2[gtk(+)]
	<gnome-base/gconf-3.2.6
	>=sys-power/upower-0.9.0
	elibc_FreeBSD? ( dev-libs/libexecinfo )

	x11-libs/libSM
	x11-libs/libICE
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXtst
	x11-apps/xdpyinfo

	x11-misc/xdg-user-dirs
	x11-misc/xdg-user-dirs-gtk"
DEPEND="${RDEPEND}
	>=dev-lang/perl-5
	>=sys-devel/gettext-0.10.40
	virtual/pkgconfig
	>=dev-util/intltool-0.40
	gnome-base/gnome-common
	!<gnome-base/gdm-2.20.4
	doc? (
		app-text/xmlto
		dev-libs/libxslt )"
# gnome-common needed for eautoreconf
# gnome-base/gdm does not provide gnome.desktop anymore

pkg_setup() {
	# TODO: convert libnotify to a configure option
	G2CONF="${G2CONF}
		--docdir="${EPREFIX}/usr/share/doc/${PF}"
		--with-default-wm=gnome-wm
		--with-gtk=2.0
		$(use_enable doc docbook-docs)
		$(use_enable ipv6)"
	DOCS="AUTHORS ChangeLog NEWS README"
}

src_prepare() {
	# Add "session saving" button back, upstream bug #575544
	epatch "${FILESDIR}/${PN}-2.32.0-session-saving-button.patch"

	# Fix support for GNOME3 conditions, bug #XXXXXX
	epatch "${FILESDIR}/${PN}-2.32.1-gnome3-conditions.patch"

	# Also support Gsettings conditions to work with libcanberra
	epatch "${FILESDIR}/${PN}-2.32.1-gsettings-conditions.patch"

	# gsm: Fix race condition in idle monitor
	epatch "${FILESDIR}/${PN}-2.32.1-idle-transition.patch"

	# Fix dialog size
	epatch "${FILESDIR}/${PN}-2.32.1-dialog-size.patch"
	epatch "${FILESDIR}/${PN}-2.32.1-dialog-size2.patch"

	intltoolize --force --copy --automake || die "intltoolize failed"
	eautoreconf
	gnome2_src_prepare
}

src_install() {
	gnome2_src_install

	dodir /etc/X11/Sessions
	exeinto /etc/X11/Sessions
	doexe "${FILESDIR}/Gnome"

	dodir /usr/share/gnome/applications/
	insinto /usr/share/gnome/applications/
	doins "${FILESDIR}/defaults.list"

	dodir /etc/X11/xinit/xinitrc.d/
	exeinto /etc/X11/xinit/xinitrc.d/
	doexe "${FILESDIR}/15-xdg-data-gnome"

	# This should be done here as discussed in bug #270852
	doexe "${FILESDIR}/10-user-dirs-update-gnome"
}
