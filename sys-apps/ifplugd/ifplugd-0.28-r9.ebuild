# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit eutils

DESCRIPTION="Brings up/down ethernet ports automatically with cable detection"
HOMEPAGE="http://0pointer.de/lennart/projects/ifplugd/"
SRC_URI="http://0pointer.de/lennart/projects/ifplugd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="doc"

DEPEND="virtual/pkgconfig
	doc? ( www-client/lynx )
	>=dev-libs/libdaemon-0.5"
RDEPEND=">=dev-libs/libdaemon-0.5
	>=sys-apps/baselayout-1.12"

src_prepare() {
	epatch "${FILESDIR}/${P}-nlapi.diff"
	epatch "${FILESDIR}/${P}-interface.patch"
	epatch "${FILESDIR}/${P}-strictalias.patch"
	epatch "${FILESDIR}/${P}-noip.patch"
}

src_configure() {
	econf \
		$(use_enable doc lynx) \
		--with-initdir=/etc/init.d \
		--disable-xmltoman \
		--disable-subversion
}

src_install() {
	default

	# Remove init.d configuration as we no longer use it
	rm -rf "${D}/etc/ifplugd" "${D}/etc/init.d/${PN}"

	exeinto "/etc/${PN}"
	newexe "${FILESDIR}/${PN}.action-r1" "${PN}.action"

	cd "${S}/doc"
	dodoc README SUPPORTED_DRIVERS
	use doc && dohtml *.html *.css
}

pkg_postinst() {

	if [ -e "${ROOT}/etc/init.d/ifplugd" -o -e "${ROOT}/etc/conf.d/ifplugd" ] ; then
		echo
		ewarn "You should stop the ifplugd service now and remove its init"
		ewarn "script and config file"
		if [ "${ROOT}" = "/" ] ; then
			ewarn "   /etc/init.d/ifplugd stop"
			ewarn "   rc-update del ifplugd"
			ewarn "   rm -f /etc/{conf,init}.d/ifplugd"
		fi
	fi
}
