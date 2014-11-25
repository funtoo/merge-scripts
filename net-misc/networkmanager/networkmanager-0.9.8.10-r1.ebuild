# Distributed under the terms of the GNU General Public License v2

EAPI="5"
GNOME_ORG_MODULE="NetworkManager"
VALA_MIN_API_VERSION="0.18"
VALA_USE_DEPEND="vapigen"

inherit bash-completion-r1 eutils gnome.org linux-info systemd user readme.gentoo toolchain-funcs vala virtualx udev

DESCRIPTION="Universal network configuration daemon for laptops, desktops, servers and virtualization hosts"
HOMEPAGE="https://wiki.gnome.org/Projects/NetworkManager"

LICENSE="GPL-2+"
SLOT="0"
IUSE="avahi bluetooth connection-sharing consolekit dhclient +dhcpcd gnutls introspection kernel_linux +nss modemmanager policykit ppp resolvconf systemd test upower vala wext +wifi"

KEYWORDS="*"

REQUIRED_USE="
	modemmanager? ( ppp )
	^^ ( nss gnutls )
	^^ ( dhclient dhcpcd )
"

PLUGINS="openconnect openswan openvpn pptp sstp vpnc"

for PLUGIN in ${PLUGINS}; do
	IUSE="${IUSE} plugins_${PLUGIN}"
done

COMMON_DEPEND="
	>=sys-apps/dbus-1.2
	>=dev-libs/dbus-glib-0.94
	>=dev-libs/glib-2.30
	<dev-libs/libnl-3.2.25:3=
	policykit? ( >=sys-auth/polkit-0.106 )
	>=net-libs/libsoup-2.26:2.4=
	virtual/libgudev:=
	bluetooth? (
		net-wireless/rfkill
		>=net-wireless/bluez-4.82 )
	avahi? ( net-dns/avahi:=[autoipd] )
	connection-sharing? (
		net-dns/dnsmasq[dhcp]
		net-firewall/iptables )
	gnutls? (
		dev-libs/libgcrypt:0=
		net-libs/gnutls:= )
	modemmanager? ( >=net-misc/modemmanager-0.7.991 )
	nss? ( >=dev-libs/nss-3.11:= )
	dhclient? ( =net-misc/dhcp-4*[client] )
	dhcpcd? ( >=net-misc/dhcpcd-4.0.0_rc3 )
	introspection? ( >=dev-libs/gobject-introspection-0.10.3 )
	ppp? ( >=net-dialup/ppp-2.4.5[ipv6] )
	resolvconf? ( net-dns/openresolv )
	systemd? ( >=sys-apps/systemd-183:0= )
	upower? ( || ( sys-power/upower sys-power/upower-pm-utils ) )

	plugins_openconnect? ( net-misc/networkmanager-openconnect )
	plugins_openswan? ( net-misc/networkmanager-openswan )
	plugins_openvpn? ( net-misc/networkmanager-openvpn )
	plugins_pptp? ( net-misc/networkmanager-pptp )
	plugins_sstp? ( net-misc/networkmanager-sstp )
	plugins_vpnc? ( net-misc/networkmanager-vpnc )
"
RDEPEND="${COMMON_DEPEND}
	virtual/udev
	consolekit? ( sys-auth/consolekit )
	wifi? (
		net-wireless/rfkill
		>=net-wireless/wpa_supplicant-0.7.3-r3[dbus] )
"
DEPEND="${COMMON_DEPEND}
	dev-util/gtk-doc-am
	>=dev-util/intltool-0.40
	>=sys-devel/gettext-0.17
	>=sys-kernel/linux-headers-2.6.29
	virtual/pkgconfig
	vala? ( $(vala_depend) )
	test? (
		dev-lang/python:2.7
		dev-python/dbus-python[python_targets_python2_7]
		dev-python/pygobject:2[python_targets_python2_7] )
"

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

pkg_pretend() {
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

pkg_setup() {
	enewgroup plugdev
}

src_prepare() {
	DOC_CONTENTS="To modify system network connections without needing to enter the
		root password, add your user account to the 'plugdev' group."

	# Bug #402085, https://bugzilla.gnome.org/show_bug.cgi?id=387832
	epatch "${FILESDIR}/${PN}-0.9.8.4-pre-sleep.patch"

	# https://www.mail-archive.com/networkmanager-list@gnome.org/msg24038.html
	epatch "${FILESDIR}/${PN}-0.9.8.9-fix-crash-on-wifi-rescan.patch"

	# Use python2.7 shebangs for test scripts
	sed -e 's@\(^#!.*python\)@\12.7@' \
		-i */tests/*.py || die

	# Fix completiondir, avoid eautoreconf, bug #465100
	sed -i "s|^completiondir =.*|completiondir = $(get_bashcompdir)|" \
		cli/completion/Makefile.in || die "sed completiondir failed"

	## Force use of /run, avoid eautoreconf
	sed -e 's:$localstatedir/run/:/run/:' -i configure || die

	use vala && vala_src_prepare

	epatch_user # don't remove, users often want custom patches for NM
}

src_configure() {
	local myconf

	if use systemd || use upower ; then

		myconf="${myconf} --with-suspend-resume=$(usex systemd systemd upower)"

	fi

	econf \
		--disable-more-warnings \
		--disable-static \
		--localstatedir=/var \
		$(usex systemd '--disable-ifnet' '--enable-ifnet') \
		--without-netconfig \
		--with-dbus-sys-dir=/etc/dbus-1/system.d \
		--with-udev-dir="$(get_udevdir)" \
		--with-iptables=/sbin/iptables \
		--enable-concheck \
		--with-crypto=$(usex nss nss gnutls) \
		--with-session-tracking=$(usex systemd systemd $(usex consolekit consolekit no)) \
		${myconf} \
		$(use_enable introspection) \
		$(use_enable ppp) \
		--disable-wimax \
		$(use_with dhclient) \
		$(use_with dhcpcd) \
		$(use_with modemmanager modem-manager-1) \
		$(use_with resolvconf) \
		$(use_enable test tests) \
		$(use_enable vala) \
		$(use_with wext) \
		"$(systemd_with_unitdir)"
}

src_test() {
	# bug #????
	cp libnm-util/tests/certs/test_ca_cert.pem src/settings/plugins/ifnet/tests/ || die
	Xemake check
}

src_install() {
	default

	readme.gentoo_create_doc

	# Gentoo init script
	newinitd "${FILESDIR}/init.d.NetworkManager" NetworkManager

	# /var/run/NetworkManager is used by some distros, but not by Gentoo
	rmdir -v "${ED}/var/run/NetworkManager" || die "rmdir failed"

	# Need to keep the /etc/NetworkManager/dispatched.d for dispatcher scripts
	keepdir /etc/NetworkManager/dispatcher.d

	# Add keyfile plugin support
	keepdir /etc/NetworkManager/system-connections
	chmod 0600 "${ED}"/etc/NetworkManager/system-connections/.keep* # bug #383765

	if ! use systemd; then
		insinto /etc/NetworkManager
		newins "${FILESDIR}/nm-system-settings.conf-ifnet" NetworkManager.conf
	fi

	# Allow users in plugdev group to modify system connections
	insinto /usr/share/polkit-1/rules.d/
	doins "${FILESDIR}/01-org.freedesktop.NetworkManager.settings.modify.system.rules"

	prune_libtool_files --modules

	# Funtoo addwifi script
	newsbin ${FILESDIR}/addwifi-with-delay addwifi
}

pkg_postinst() {
	readme.gentoo_print_elog

	if [[ -e "${EROOT}etc/NetworkManager/nm-system-settings.conf" ]]; then
		ewarn "The ${PN} system configuration file has moved to a new location."
		ewarn "You must migrate your settings from ${EROOT}/etc/NetworkManager/nm-system-settings.conf"
		ewarn "to ${EROOT}etc/NetworkManager/NetworkManager.conf"
		ewarn
		ewarn "After doing so, you can remove ${EROOT}etc/NetworkManager/nm-system-settings.conf"
	fi

	# The polkit rules file moved to /usr/share
	old_rules="${EROOT}etc/polkit-1/rules.d/01-org.freedesktop.NetworkManager.settings.modify.system.rules"
	if [[ -f "${old_rules}" ]]; then
		case "$(md5sum ${old_rules})" in
		  574d0cfa7e911b1f7792077003060240* )
			# Automatically delete the old rules.d file if the user did not change it
			elog
			elog "Removing old ${old_rules} ..."
			rm -f "${old_rules}" || eerror "Failed, please remove ${old_rules} manually"
			;;
		  * )
			elog "The ${old_rules}"
			elog "file moved to /usr/share/polkit-1/rules.d/ in >=networkmanager-0.9.4.0-r4"
			elog "If you edited ${old_rules}"
			elog "without changing its behavior, you may want to remove it."
			;;
		esac
	fi

	if use systemd; then
		if [[ ${REPLACING_VERSIONS} < 0.9.8.6 ]]; then
			ewarn "Ifnet plugin won't be used with systemd support enabled"
			ewarn "as it is meant to be used with openRC and can cause collisions"
			ewarn "(like bug #485658)."
			ewarn "Because of this, you will likely need to reconfigure some of"
			ewarn "your networks."
		fi

		if [[ -e "${EROOT}etc/NetworkManager/NetworkManager.conf" ]]; then
			if grep -q plugins "${EROOT}etc/NetworkManager/NetworkManager.conf" | grep -q ifnet; then
				ewarn "You seem to use 'ifnet' plugin in ${EROOT}etc/NetworkManager/NetworkManager.conf"
				ewarn "Since it won't be used when running under Systemd, you will need to stop setting"
				ewarn "ifnet plugin there to allow NetworkManager to work."
			fi
		fi
	fi
}
