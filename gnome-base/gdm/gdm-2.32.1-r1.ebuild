# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/gdm/gdm-2.32.1-r1.ebuild,v 1.6 2012/09/27 08:54:42 tetromino Exp $

EAPI="3"
GCONF_DEBUG="yes"

inherit autotools eutils gnome2 pam user

DESCRIPTION="GNOME Display Manager"
HOMEPAGE="https://live.gnome.org/GDM"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~sh ~sparc ~x86"

IUSE_LIBC="elibc_glibc"
IUSE="accessibility +consolekit ipv6 gnome-keyring selinux tcpd test xinerama +xklavier $IUSE_LIBC"

# Name of the tarball with gentoo specific files
GDM_EXTRA="${PN}-2.20.9-gentoo-files-r1"

SRC_URI="${SRC_URI}
	mirror://gentoo/${GDM_EXTRA}.tar.bz2"

# NOTE: x11-base/xorg-server dep is for X_SERVER_PATH etc, bug #295686
RDEPEND="
	>=dev-libs/dbus-glib-0.74
	>=dev-libs/glib-2.22:2
	>=x11-libs/gtk+-2.20.2:2
	>=x11-libs/pango-1.3
	>=media-libs/libcanberra-0.4[gtk]
	>=gnome-base/gconf-2.31.3
	>=gnome-base/gnome-panel-2[bonobo]
	<gnome-base/gnome-panel-2.91
	>=gnome-base/gnome-session-2.28
	>=x11-misc/xdg-utils-1.0.2-r3
	>=sys-power/upower-0.9
	app-text/iso-codes

	x11-base/xorg-server
	x11-libs/libXi
	x11-libs/libXau
	x11-libs/libX11
	x11-libs/libXdmcp
	x11-libs/libXext
	x11-libs/libXft
	x11-apps/sessreg

	virtual/pam
	consolekit? ( sys-auth/consolekit )

	accessibility? ( x11-libs/libXevie )
	gnome-keyring? ( >=gnome-base/gnome-keyring-2.22[pam] )
	selinux? ( sys-libs/libselinux )
	tcpd? ( >=sys-apps/tcp-wrappers-7.6 )
	xinerama? ( x11-libs/libXinerama )
	xklavier? ( >=x11-libs/libxklavier-4 )

	!gnome-extra/fast-user-switch-applet"
DEPEND="${RDEPEND}
	test? ( >=dev-libs/check-0.9.4 )
	xinerama? ( x11-proto/xineramaproto )
	app-text/docbook-xml-dtd:4.1.2
	sys-devel/gettext
	x11-proto/inputproto
	>=dev-util/intltool-0.40
	virtual/pkgconfig
	>=app-text/scrollkeeper-0.1.4
	>=app-text/gnome-doc-utils-0.3.2"

pkg_setup() {
	DOCS="AUTHORS ChangeLog NEWS README TODO"

	# PAM is the only auth scheme supported
	# even though configure lists shadow and crypt
	# they don't have any corresponding code
	G2CONF="${G2CONF}
		--disable-schemas-install
		--localstatedir=/var
		--with-xdmcp=yes
		--enable-authentication-scheme=pam
		--with-pam-prefix=/etc
		SOUND_PROGRAM=/usr/bin/gdmplay
		$(use_with accessibility xevie)
		$(use_enable ipv6)
		$(use_enable xklavier libxklavier)
		$(use_with consolekit console-kit)
		$(use_with selinux)
		$(use_with tcpd tcp-wrappers)
		$(use_with xinerama)"

	enewgroup gdm
	enewuser gdm -1 -1 /var/lib/gdm gdm
}

src_prepare() {
	gnome2_src_prepare

	# remove unneeded linker directive for selinux, bug #41022
	epatch "${FILESDIR}/${PN}-2.32.0-selinux-remove-attr.patch"

	# daemonize so that the boot process can continue, bug #236701
	epatch "${FILESDIR}/${PN}-2.32.0-fix-daemonize-regression.patch"

	# GDM grabs VT2 instead of VT7, bug 261339, bug 284053, bug 288852
	epatch "${FILESDIR}/${PN}-2.32.0-fix-vt-problems.patch"

	# make custom session work, bug #216984
	epatch "${FILESDIR}/${PN}-2.32.0-custom-session.patch"

	# ssh-agent handling must be done at xinitrc.d, bug #220603
	epatch "${FILESDIR}/${PN}-2.32.0-xinitrc-ssh-agent.patch"

	# fix libxklavier automagic support
	epatch "${FILESDIR}/${PN}-2.32.0-automagic-libxklavier-support.patch"

	mkdir "${S}"/m4
	intltoolize --force --copy --automake || die "intltoolize failed"
	eautoreconf
}

src_install() {
	gnome2_src_install

	local gentoodir="${WORKDIR}/${GDM_EXTRA}"

	# gdm-binary should be gdm to work with our init (#5598)
	rm -f "${D}/usr/sbin/gdm"
	dosym /usr/sbin/gdm-binary /usr/sbin/gdm

	# our x11's scripts point to /usr/bin/gdm
	dosym /usr/sbin/gdm-binary /usr/bin/gdm

	# log, etc.
	keepdir /var/log/gdm
	keepdir /var/gdm

	fowners root:gdm /var/gdm
	fperms 1770 /var/gdm

	# add a custom xsession .desktop by default (#44537)
	exeinto /etc/X11/dm/Sessions
	doexe "${gentoodir}/custom.desktop" || die "doexe 1 failed"

	# add xinitrc.d scripts
	exeinto /etc/X11/xinit/xinitrc.d
	doexe "${FILESDIR}/49-keychain" || die "doexe 2 failed"
	doexe "${FILESDIR}/50-ssh-agent" || die "doexe 3 failed"

	# install XDG_DATA_DIRS gdm changes
	echo 'XDG_DATA_DIRS="/usr/share/gdm"' > 99xdg-gdm
	doenvd 99xdg-gdm || die "doenvd failed"

	# add a custom sound playing script (#248253)
	dobin "${gentoodir}/gdmplay"

	# avoid file collision, bug #213118
	rm -f "${D}/usr/share/xsessions/gnome.desktop"

	# We replace the pam stuff by our own
	rm -rf "${D}/etc/pam.d"

	use gnome-keyring && sed -i "s:#Keyring=::g" "${gentoodir}"/pam.d/*

	dopamd "${gentoodir}"/pam.d/*
	dopamsecurity console.apps "${gentoodir}/security/console.apps/gdmsetup"
}

pkg_postinst() {
	gnome2_pkg_postinst

	ewarn
	ewarn "This is an EXPERIMENTAL release, please bear with its bugs and"
	ewarn "visit us on #gentoo-desktop if you have problems."
	ewarn

	elog "To make GDM start at boot, edit /etc/conf.d/xdm"
	elog "and then execute 'rc-update add xdm default'."
	elog "If you already have GDM running, you will need to restart it."

	if use gnome-keyring; then
		elog "For autologin to unlock your keyring, you need to set an empty"
		elog "password on your keyring. Use app-crypt/seahorse for that."
	fi

	if [ -f "/etc/X11/gdm/gdm.conf" ]; then
		elog "You had /etc/X11/gdm/gdm.conf which is the old configuration"
		elog "file.  It has been moved to /etc/X11/gdm/gdm-pre-gnome-2.16"
		mv /etc/X11/gdm/gdm.conf /etc/X11/gdm/gdm-pre-gnome-2.16
	fi
}

pkg_postrm() {
	gnome2_pkg_postrm

	if rc-config list default | grep -q xdm; then
		elog "To remove GDM from startup please execute"
		elog "'rc-update del xdm default'"
	fi
}
