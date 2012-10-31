# Distributed under the terms of the GNU General Public License v2

EAPI="3"
GNOME_ORG_MODULE="NetworkManager"

inherit autotools eutils gnome.org linux-info systemd

DESCRIPTION="Network configuration and management in an easy way. Desktop environment independent."
HOMEPAGE="http://www.gnome.org/projects/NetworkManager/"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="amd64 ~arm ppc ppc64 x86"
IUSE="avahi bluetooth doc nss gnutls dhclient dhcpcd kernel_linux +ppp resolvconf connection-sharing"

RDEPEND=">=sys-apps/dbus-1.2
	>=dev-libs/dbus-glib-0.75
	>=net-wireless/wireless-tools-28_pre9
	|| ( >=sys-fs/udev-171[gudev] >=sys-fs/udev-145[extras] )
	>=dev-libs/glib-2.18
	>=sys-auth/polkit-0.92
	>=dev-libs/libnl-1.1:1.1
	ppp? ( >=net-misc/modemmanager-0.4
		>=net-dialup/ppp-2.4.5 )
	>=net-wireless/wpa_supplicant-0.5.10[dbus]
	bluetooth? ( net-wireless/bluez )
	|| ( sys-libs/e2fsprogs-libs <sys-fs/e2fsprogs-1.41.0 )
	avahi? ( net-dns/avahi[autoipd] )
	gnutls? (
		nss? ( >=dev-libs/nss-3.11 )
		!nss? ( dev-libs/libgcrypt
			net-libs/gnutls ) )
	!gnutls? ( >=dev-libs/nss-3.11 )
	dhclient? (
		dhcpcd? ( >=net-misc/dhcpcd-4.0.0_rc3 )
		!dhcpcd? ( net-misc/dhcp[client] ) )
	!dhclient? ( >=net-misc/dhcpcd-4.0.0_rc3 )
	resolvconf? ( net-dns/openresolv )
	connection-sharing? (
		net-dns/dnsmasq
		net-firewall/iptables )"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	dev-util/intltool
	doc? ( >=dev-util/gtk-doc-1.8 )"

sysfs_deprecated_check() {
	ebegin "Checking for SYSFS_DEPRECATED support"

	if { linux_chkconfig_present SYSFS_DEPRECATED_V2; }; then
		eerror "Please disable SYSFS_DEPRECATED_V2 support in your kernel config and recompile your kernel"
		eerror "or NetworkManager will not work correctly."
		eerror "See http://bugs.gentoo.org/333639 for more info."
		die "CONFIG_SYSFS_DEPRECATED_V2 support detected!"
	fi
	eend $?
}

pkg_setup() {
	if use kernel_linux; then
		get_version
		if linux_config_exists; then
			sysfs_deprecated_check
		else
			ewarn "Was unable to determine your kernel .config"
			ewarn "Please note that if CONFIG_SYSFS_DEPRECATED_V2 is set in your kernel .config, NetworkManager will not work correctly."
			ewarn "See http://bugs.gentoo.org/333639 for more info."
		fi

	fi
}

src_prepare() {
	# backported ifnet patches
	epatch "${FILESDIR}/${P}-shared-connection.patch"
	epatch "${FILESDIR}/${P}-fix-tests.patch"
	epatch "${FILESDIR}/${P}-ifnet-smarter-write.patch"
	# Fix building against linux-headers-3.4, #417055
	epatch "${FILESDIR}/${PN}-0.9.4.0-ip_ppp.h.patch"
	eautoreconf
}

src_configure() {
	ECONF="--disable-more-warnings
		--disable-static
		--localstatedir=/var
		--with-distro=gentoo
		--with-dbus-sys-dir=/etc/dbus-1/system.d
		--with-udev-dir=/lib/udev
		--with-iptables=/sbin/iptables
		$(use_enable doc gtk-doc)
		$(use_with doc docs)
		$(use_enable ppp)
		$(use_with resolvconf)
		$(systemd_with_unitdir)"

	# default is dhcpcd (if none or both are specified), ISC dchclient otherwise
	if use dhclient ; then
		if use dhcpcd ; then
			ECONF="${ECONF} --with-dhcpcd --without-dhclient"
		else
			ECONF="${ECONF} --with-dhclient --without-dhcpcd"
		fi
	else
		ECONF="${ECONF} --with-dhcpcd --without-dhclient"
	fi

	# default is NSS (if none or both are specified), GnuTLS otherwise
	if use gnutls ; then
		if use nss ; then
			ECONF="${ECONF} --with-crypto=nss"
		else
			ECONF="${ECONF} --with-crypto=gnutls"
		fi
	else
		ECONF="${ECONF} --with-crypto=nss"
	fi

	econf ${ECONF}
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	# Need to keep the /var/run/NetworkManager directory
	keepdir /var/run/NetworkManager

	# Need to keep the /etc/NetworkManager/dispatched.d for dispatcher scripts
	keepdir /etc/NetworkManager/dispatcher.d

	dodoc AUTHORS ChangeLog NEWS README TODO || die "dodoc failed"

	# Add keyfile plugin support
	keepdir /etc/NetworkManager/system-connections
	insinto /etc/NetworkManager
	newins "${FILESDIR}/nm-system-settings.conf-ifnet" nm-system-settings.conf \
		|| die "newins failed"

	# Remove useless .la files
	find "${D}" -name '*.la' -exec rm -f {} + || die "la file removal failed"
}

pkg_postinst() {
	elog "You will need to reload DBus if this is your first time installing"
	elog "NetworkManager, or if you're upgrading from 0.7 or older."
	elog ""
}
