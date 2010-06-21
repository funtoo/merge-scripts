# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/banshee/banshee-1.6.0.ebuild,v 1.2 2010/04/01 11:59:34 ford_prefect Exp $

EAPI=2

inherit eutils mono gnome2-utils fdo-mime versionator

GVER=0.10.7

DESCRIPTION="Import, organize, play, and share your music using a simple and powerful interface."
HOMEPAGE="http://banshee-project.org"

#BANSHEE_V2=$(get_version_component_range 2)
#[[ $((${BANSHEE_V2} % 2)) -eq 0 ]] && RELTYPE=stable || RELTYPE=unstable
#SRC_URI="http://download.banshee-project.org/${PN}/${RELTYPE}/${PV}/${PN}-1-${PV}.tar.bz2"
SRC_URI="http://download.banshee-project.org/${PN}/stable/${PV}/${PN}-1-${PV}.tar.bz2"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+aac +cdda boo daap doc +encode ipod karma mtp podcast test wikipedia youtube"

RDEPEND=">=dev-lang/mono-2.4.3
	gnome-base/gnome-settings-daemon
	x11-themes/gnome-icon-theme
	sys-apps/dbus
	>=dev-dotnet/gtk-sharp-2.12
	>=dev-dotnet/gconf-sharp-2.24.0
	>=dev-dotnet/notify-sharp-0.4.0_pre20080912-r1
	>=media-libs/gstreamer-0.10.21-r3
	>=media-libs/gst-plugins-base-0.10.25.2
	>=media-libs/gst-plugins-bad-${GVER}
	>=media-libs/gst-plugins-good-${GVER}
	>=media-libs/gst-plugins-ugly-${GVER}
	>=media-plugins/gst-plugins-meta-0.10-r2:0.10
	>=media-plugins/gst-plugins-gnomevfs-${GVER}
	>=media-plugins/gst-plugins-gconf-${GVER}
	cdda? (
		|| (
			>=media-plugins/gst-plugins-cdparanoia-${GVER}
			>=media-plugins/gst-plugins-cdio-${GVER}
		)
	)
	media-libs/musicbrainz:1
	>=dev-dotnet/dbus-glib-sharp-0.4.1
	>=dev-dotnet/dbus-sharp-0.6.1a
	>=dev-dotnet/mono-addins-0.4[gtk]
	>=dev-dotnet/taglib-sharp-2.0.3.7
	>=dev-db/sqlite-3.4
	karma? ( >=media-libs/libkarma-0.1.0-r1 )
	aac? ( >=media-plugins/gst-plugins-faad-${GVER} )
	boo? (
		>=dev-lang/boo-0.8.1
	)
	daap? (
		>=dev-dotnet/mono-zeroconf-0.8.0-r1
	)
	doc? (
		virtual/monodoc
	)
	encode? (
		>=media-plugins/gst-plugins-lame-${GVER}
		>=media-plugins/gst-plugins-taglib-${GVER}
	)
	ipod? (
		>=dev-dotnet/ipod-sharp-0.8.5
	)
	mtp? (
		media-libs/libmtp
	)
	wikipedia? (
		>=dev-dotnet/webkit-sharp-0.2
	)
	youtube? (
		>=dev-dotnet/google-gdata-sharp-1.4
	)"

DEPEND="${RDEPEND}
	dev-util/pkgconfig"

DOCS="AUTHORS ChangeLog HACKING NEWS README"

S=${WORKDIR}/${PN}-1-${PV}

src_prepare () {
	# Fix intltool b0rkage similar to
	# https://bugzilla.gnome.org/show_bug.cgi?id=577133
	sed "s:'\^\$\$lang\$\$':\^\$\$lang\$\$:g" -i po/Makefile.in.in \
		|| die "sed failed"
}

src_configure() {
	local myconf="--disable-dependency-tracking --disable-static
		--enable-gnome --enable-schemas-install
		--with-gconf-schema-file-dir=/etc/gconf/schemas
		--with-vendor-build-id=Gentoo/${PN}/${PVR}
		--enable-gapless-playback
		--disable-torrent
		--disable-shave"

	econf \
		$(use_enable doc docs) \
		$(use_enable boo) \
		$(use_enable mtp) \
		$(use_enable daap) \
		$(use_enable ipod) \
		$(use_enable podcast) \
		$(use_enable karma) \
		$(use_enable wikipedia webkit) \
		$(use_enable youtube) \
		${myconf}
}

src_compile() {
	emake MCS=/usr/bin/gmcs
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install efailed"
	find "${D}" -name '*.la' -delete
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	ewarn
	ewarn "If ${PN} doesn't play some format, please check your"
	ewarn "USE flags on media-plugins/gst-plugins-meta"
	ewarn

	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
}
