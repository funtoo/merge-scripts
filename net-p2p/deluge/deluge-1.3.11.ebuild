# Distributed under the terms of the GNU General Public License v2

EAPI=5-progress
PYTHON_MULTIPLE_ABIS=1
PYTHON_RESTRICTED_ABIS="3.* *-jython *-pypy-*"

inherit distutils eutils

DESCRIPTION="BitTorrent client with a client/server model"
HOMEPAGE="http://deluge-torrent.org/"
SRC_URI="http://download.deluge-torrent.org/source/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="geoip gtk libnotify setproctitle sound +webinterface"

DEPEND="( $(python_abi_depend dev-python/setuptools) >=net-libs/rb_libtorrent-0.14.9[python] dev-util/intltool )"
RDEPEND="${DEPEND} $(python_abi_depend	dev-python/chardet dev-python/pyopenssl dev-python/pyxdg dev-python/simplejson dev-python/twisted-core dev-python/twisted-web)
	geoip? ( dev-libs/geoip )
	gtk? ( $(python_abi_depend dev-python/pygobject:2 dev-python/pygtk:2) gnome-base/librsvg )
	libnotify? ( $(python_abi_depend dev-python/notify-python) )
	sound? ( $(python_abi_depend dev-python/pygame) )
	setproctitle? ( $(python_abi_depend dev-python/setproctitle) )
	webinterface? ( $(python_abi_depend dev-python/mako) )"

pkg_setup() {
	python_pkg_setup
}

src_prepare() {
	distutils_src_prepare
	python_convert_shebangs -r 2 .
	epatch "${FILESDIR}/${PN}-1.3.5-disable_libtorrent_internal_copy.patch"

}

src_install() {
	distutils_src_install
	newinitd "${FILESDIR}"/deluged.init-1 deluged
	newconfd "${FILESDIR}"/deluged.conf deluged
}

pkg_postinst() {
	distutils_pkg_postinst
	elog
	elog "If after upgrading it doesn't work, please remove the"
	elog "'~/.config/deluge' directory and try again, but make a backup"
	elog "first!"
	elog
	elog "To start the daemon either run 'deluged' as user"
	elog "or modify /etc/conf.d/deluged and run"
	elog "/etc/init.d/deluged start as root"
	elog "You can still use deluge the old way"
	elog
	elog "For more information look at http://dev.deluge-torrent.org/wiki/Faq"
	elog
}
