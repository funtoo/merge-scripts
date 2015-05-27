# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit autotools

DESCRIPTION="Pulseaudio Volume Control, GTK based mixer for Pulseaudio"
HOMEPAGE="http://freedesktop.org/software/pulseaudio/pavucontrol"
SRC_URI="http://freedesktop.org/software/pulseaudio/${PN}/${P}.tar.xz"

RESTRICT="mirror"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="+gtk2
	gtk3 nls"

REQUIRED_USE="^^ ( gtk2 gtk3 )"

RDEPEND="media-sound/pulseaudio[glib]
	virtual/freedesktop-icon-theme
	dev-libs/libsigc++:2
	gtk2? ( dev-cpp/gtkmm:2.4
		media-libs/libcanberra[gtk] )
	gtk3? ( dev-cpp/gtkmm:3.0
		media-libs/libcanberra[gtk3] )"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	nls? ( dev-util/intltool
		sys-devel/gettext )"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf --docdir=/usr/share/doc/${PF} \
		--htmldir=/usr/share/doc/${PF}/html \
		--disable-lynx \
		$(use_enable gtk3) \
		$(use_enable nls)
}
