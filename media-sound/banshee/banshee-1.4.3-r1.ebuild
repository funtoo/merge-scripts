# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/banshee/banshee-1.4.3-r1.ebuild,v 1.5 2009/06/06 09:39:48 ssuominen Exp $

EAPI=2
inherit eutils mono gnome2-utils fdo-mime versionator

DESCRIPTION="Import, organize, play, and share your music using a simple and powerful interface."
HOMEPAGE="http://banshee-project.org"

BANSHEE_V2=$(get_version_component_range 2)
[[ $((${BANSHEE_V2} % 2)) -eq 0 ]] && RELTYPE=stable || RELTYPE=unstable
SRC_URI="http://download.banshee-project.org/${PN}/${RELTYPE}/${PV}/${PN}-1-${PV}.tar.bz2
	mirror://gentoo/banshee-1.4.2-musicbrainz-fix.patch.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="+aac boo daap doc +encode +flac ipod karma +mad mtp podcast test +vorbis"

RDEPEND=">=dev-lang/mono-2
	gnome-base/gnome-settings-daemon
	x11-themes/gnome-icon-theme
	sys-apps/dbus
	>=dev-dotnet/gtk-sharp-2.12
	>=dev-dotnet/gconf-sharp-2.24.0
	>=dev-dotnet/gnome-sharp-2.24.0
	>=dev-dotnet/notify-sharp-0.4.0_pre20080912-r1
	>=media-libs/gstreamer-0.10.21-r3:0.10
	media-libs/gst-plugins-bad
	media-libs/gst-plugins-good:0.10
	media-libs/gst-plugins-ugly:0.10
	media-plugins/gst-plugins-alsa:0.10
	media-plugins/gst-plugins-gnomevfs:0.10
	media-plugins/gst-plugins-gconf:0.10
	|| ( media-plugins/gst-plugins-cdparanoia:0.10
		media-plugins/gst-plugins-cdio:0.10 )
	media-libs/musicbrainz:1
	>=dev-dotnet/dbus-glib-sharp-0.4.1
	>=dev-dotnet/dbus-sharp-0.6.1a
	>=dev-dotnet/mono-addins-0.4[gtk]
	>=dev-dotnet/taglib-sharp-2.0.3.1
	>=dev-db/sqlite-3.4
	karma? ( >=media-libs/libkarma-0.1.0-r1 )
	aac? ( media-plugins/gst-plugins-faad:0.10 )
	boo? ( >=dev-lang/boo-0.8.1 )
	daap? ( >=dev-dotnet/mono-zeroconf-0.8.0-r1 )
	doc? ( virtual/monodoc )
	encode? ( media-plugins/gst-plugins-lame:0.10
		media-plugins/gst-plugins-taglib:0.10 )
	flac? ( media-plugins/gst-plugins-flac:0.10 )
	ipod? ( >=dev-dotnet/ipod-sharp-0.8.1 )
	mad? ( media-plugins/gst-plugins-mad:0.10 )
	mtp? ( media-libs/libmtp )
	vorbis? ( media-plugins/gst-plugins-ogg:0.10
		media-plugins/gst-plugins-vorbis:0.10 )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

DOCS="AUTHORS ChangeLog HACKING NEWS README"

S=${WORKDIR}/${PN}-1-${PV}

src_prepare() {
	epatch "${FILESDIR}/${PN}-1.4.2-metadata-writefail.patch"

	#Upstream bug 527788, our bug 249620
	#tacorner@cornersplace.org is author
	epatch "${WORKDIR}/${PN}-1.4.2-musicbrainz-fix.patch"
}

src_configure() {
	local myconf="--disable-dependency-tracking --disable-static
		--enable-gnome --enable-schemas-install
		--with-gconf-schema-file-dir=/etc/gconf/schemas
		--with-vendor-build-id=Gentoo/${PN}/${PVR}"

	econf \
		$(use_enable doc docs) \
		$(use_enable boo) \
		$(use_enable mtp) \
		$(use_enable daap) \
		$(use_enable ipod) \
		$(use_enable podcast) \
		$(use_enable karma) \
		${myconf}
}

src_compile() {
	default
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	find "${D}" -name '*.la' -delete
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
}
