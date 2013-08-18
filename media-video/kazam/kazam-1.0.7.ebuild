# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="2.5 3.* *-jython *-pypy-*"

inherit gnome2 distutils

DESCRIPTION="A screencasting program created with design in mind"
HOMEPAGE="https://launchpad.net/kazam"
SRC_URI="http://launchpad.net/${PN}/stable/${PV}/+download/${P}.tar.gz"

LICENSE="GPL-3 LGPL-3"
SLOT="0"
KEYWORDS="~*"
IUSE="pulseaudio"

DEPEND="$(python_abi_depend dev-python/python-distutils-extra)"
RDEPEND="x11-libs/gtk+:3[introspection]
	dev-python/gst-python:0.10
	$(python_abi_depend dev-python/pycairo dev-python/pyxdg dev-python/pygobject:3 dev-python/pycurl dev-python/gdata) 
	media-libs/gst-plugins-good:0.10
	media-plugins/gst-plugins-x264:0.10
	media-plugins/gst-plugins-ximagesrc:0.10
	pulseaudio? ( media-sound/pulseaudio )
	virtual/python-argparse
	virtual/ffmpeg"

pkg_setup() {
	python_pkg_setup
}

src_prepare() {
	# correct name of .desktop file
	sed -i -e 's/avidemux-gtk/avidemux2-gtk/' ${PN}/frontend/combobox.py \
		|| die
	# fix a warning: value "GNOME" requires GTK to be present
	sed -i -e 's/GNOME;/GNOME;GTK;/' data/kazam.desktop.in || die
	distutils_src_prepare
}

src_configure() {
	einfo "Nothing to configure."
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
	distutils_pkg_postinst
	echo
	elog "For optional audio recording, running PulseAudio"
	elog "(media-sound/pulseaudio) is required."
	elog
	elog "If you have media-gfx/graphviz installed, file /tmp/kazam_pipeline.png"
	elog "is created and can be used to inspect GStreamer pipeline."
	elog "This is useful for debugging."
	elog
	elog "These applications can be used to open and edit recordings directly from Kazam:"
	elog "- media-video/openshot,"
	elog "- media-video/kdenlive,"
	elog "- media-video/pitivi,"
	elog "- media-video/avidemux."
	echo
}

pkg_postrm() {
	gnome2_icon_cache_update
	distutils_pkg_postrm
}
