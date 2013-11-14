# Distributed under the terms of the GNU General Public License v2

EAPI="4"
GCONF_DEBUG="yes"
GNOME2_LA_PUNT="yes"
GNOME_TARBALL_SUFFIX="bz2"

inherit autotools eutils gnome2

DESCRIPTION="Gnome Settings Daemon"
HOMEPAGE="http://www.gnome.org"
SRC_URI="${SRC_URI} http://dev.gentoo.org/~pacho/gnome/gnome-settings-daemon-2.32.1-gst-vol-control-support.patch"

# Old patches:
# 	mirror://gentoo/${PN}-2.30.0-gst-vol-control-support.patch" -> this causes bug #327609
# 	mirror://gentoo/${PN}-2.30.2-gst-vol-control-support.patch.bz2" -> this patch has worse problems like bug #339732

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="*"
IUSE="debug libnotify policykit pulseaudio smartcard"

# libgnomekbd-2.91 breaks API/ABI
COMMON_DEPEND=">=dev-libs/dbus-glib-0.74
	>=dev-libs/glib-2.18:2
	>=x11-libs/gtk+-2.21.2:2
	>=gnome-base/gconf-2.6.1:2
	>=gnome-base/libgnomekbd-2.32.0-r1
	<gnome-base/libgnomekbd-2.91.0
	>=gnome-base/gnome-desktop-2.29.92:2

	x11-libs/libX11
	x11-libs/libXi
	x11-libs/libXext
	x11-libs/libXxf86misc
	>=x11-libs/libxklavier-5.0
	media-libs/fontconfig

	libnotify? ( >=x11-libs/libnotify-0.4.3 )
	policykit? (
		>=sys-auth/polkit-0.91
		>=dev-libs/dbus-glib-0.71
		>=sys-apps/dbus-1.1.2 )
	pulseaudio? (
		>=media-sound/pulseaudio-0.9.15
		media-libs/libcanberra[gtk] )
	!pulseaudio? (
		>=media-libs/gstreamer-0.10.1.2:0.10
		>=media-libs/gst-plugins-base-0.10.1.2:0.10 )
	smartcard? ( >=dev-libs/nss-3.11.2 )"

# 50-accessibility.xml moved to gnome-control-center in gnome-3
RDEPEND="${COMMON_DEPEND}
	!>=gnome-base/gnome-control-center-2.91.90"

DEPEND="${COMMON_DEPEND}
	!<gnome-base/gnome-control-center-2.22
	sys-devel/gettext
	>=dev-util/intltool-0.40
	virtual/pkgconfig
	x11-proto/inputproto
	x11-proto/xproto"

pkg_setup() {
	# README is empty
	DOCS="AUTHORS NEWS ChangeLog MAINTAINERS"
	G2CONF="${G2CONF}
		--disable-static
		$(use_enable debug)
		$(use_with libnotify)
		$(use_enable policykit polkit)
		$(use_enable pulseaudio pulse)
		$(use_enable !pulseaudio gstreamer)
		$(use_enable smartcard smartcard-support)"

	if use pulseaudio; then
		elog "Building volume media keys using Pulseaudio"
	else
		elog "Building volume media keys using GStreamer"
	fi
}

src_prepare() {
	gnome2_src_prepare

	# libnotify-0.7.1 compatibility patches
	epatch "${FILESDIR}"/${PN}-2.32.1-libnotify-0.7.patch
	epatch "${FILESDIR}"/${PN}-2.32.1-libnotify-init.patch

	# Restore gstreamer volume control support, upstream bug #571145
	# Keep using old patch as it doesn't cause problems like bug #339732
#	epatch "${WORKDIR}/${PN}-2.30.2-gst-vol-control-support.patch"
#	echo "plugins/media-keys/cut-n-paste/gvc-gstreamer-acme-vol.c" >> po/POTFILES.in
	# We use now debian patch as looks to fix bug #327609
#	epatch "${DISTDIR}/${PN}-2.30.0-gst-vol-control-support.patch"
	epatch "${DISTDIR}/${PN}-2.32.1-gst-vol-control-support.patch"

	# More network filesystems not to monitor, upstream bug #606421
	epatch "${FILESDIR}/${PN}-2.32.1-netfs-monitor.patch"

	# xsettings: Export Xft.lcdfilter for OO.o's benefit, upstream bug #631924
	epatch "${FILESDIR}/${PN}-2.32.1-lcdfilter.patch"

	# media-keys: React to stream-removed signal from GvcMixerControl
	epatch "${FILESDIR}/${PN}-2.32.1-media-keys-react.patch"

	# mouse: Use event driven mode for syndaemon
	epatch "${FILESDIR}/${PN}-2.32.1-syndaemon-mode.patch"

	intltoolize --force --copy --automake || die "intltoolize failed"
	eautoreconf
}

pkg_postinst() {
	gnome2_pkg_postinst

	if ! use pulseaudio; then
		elog "GStreamer volume control support is a feature powered by Gentoo GNOME Team"
		elog "PLEASE DO NOT report bugs upstream, report on https://bugs.gentoo.org instead"
	fi
}
