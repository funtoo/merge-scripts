# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils systemd udev

DESCRIPTION="D-Bus abstraction for enumerating power devices and querying history and statistics"
HOMEPAGE="http://upower.freedesktop.org/"
SRC_URI="http://${PN}.freedesktop.org/releases/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="+deprecated doc +introspection ios kernel_FreeBSD kernel_linux systemd"

COMMON_DEPEND=">=dev-libs/dbus-glib-0.100
	>=dev-libs/glib-2.22
	sys-apps/dbus
	>=sys-auth/polkit-0.110
	introspection? ( dev-libs/gobject-introspection )
	kernel_linux? (
		virtual/libusb:1
		>=virtual/udev-171[gudev]
		ios? (
			>=app-pda/libimobiledevice-1
			>=app-pda/libplist-1
			)
		systemd? ( sys-apps/systemd )
		)"
RDEPEND="${COMMON_DEPEND}
	kernel_linux? (
		deprecated? ( >=sys-power/pm-utils-1.4.1 )
		systemd? ( app-shells/bash )
		)"
DEPEND="${COMMON_DEPEND}
	dev-libs/libxslt
	app-text/docbook-xsl-stylesheets
	dev-util/intltool
	virtual/pkgconfig
	doc? (
		dev-util/gtk-doc
		app-text/docbook-xml-dtd:4.1.2
		)"
REQUIRED_USE="kernel_linux? ( !deprecated? ( systemd ) )"

QA_MULTILIB_PATHS="usr/lib/${PN}/.*"

src_prepare() {
	sed -i -e '/DISABLE_DEPRECATED/d' configure || die
}

src_configure() {
	local backend myconf

	if use kernel_linux; then
		backend=linux
		myconf="$(use_enable deprecated)"
	elif use kernel_FreeBSD; then
		backend=freebsd
	else
		backend=dummy
	fi

	econf \
		--libexecdir="${EPREFIX}"/usr/lib/${PN} \
		--localstatedir="${EPREFIX}"/var \
		$(use_enable introspection) \
		--disable-static \
		${myconf} \
		--enable-man-pages \
		$(use_enable doc gtk-doc) \
		$(use_enable systemd) \
		--disable-tests \
		--with-html-dir="${EPREFIX}"/usr/share/doc/${PF}/html \
		--with-backend=${backend} \
		$(use_with ios idevice) \
		"$(systemd_with_utildir)" \
		"$(systemd_with_unitdir)"
}

src_install() {
	emake DESTDIR="${D}" udevrulesdir="$(get_udevdir)"/rules.d install

	dodoc AUTHORS HACKING NEWS README
	keepdir /var/lib/upower #383091
	prune_libtool_files
}
