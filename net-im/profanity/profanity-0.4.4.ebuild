# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit autotools

SRC_URI="https://github.com/boothj5/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

DESCRIPTION="Ncurses based jabber client inspired by irssi"
HOMEPAGE="http://www.profanity.im"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="*"
IUSE="libnotify otr +themes xml xscreensaver"

RDEPEND="dev-libs/glib:2
	dev-libs/libstrophe[xml=]
	net-misc/curl
	sys-libs/ncurses
	libnotify? ( virtual/notification-daemon
		x11-libs/libnotify )
	otr? ( net-libs/libotr )
	xscreensaver? ( x11-libs/libXScrnSaver )"

DEPEND="${RDEPEND}"

src_prepare() {
	eautoreconf
}

src_configure() {
	econf	$(use_enable libnotify notifications) \
		$(use_enable otr) \
		$(use_with themes) \
		$(use_with xml libxml2) \
		$(use_with xscreensaver)
}

pkg_postinst() {
	elog "Profanity user guide available online at the following link:"
	elog "http://www.profanity.im/userguide.html"
}
