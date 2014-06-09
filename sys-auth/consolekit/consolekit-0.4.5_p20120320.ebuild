# Distributed under the terms of the GNU General Public License v2

EAPI=4
inherit autotools eutils linux-info pam systemd

MY_PN=ConsoleKit
MY_P=${MY_PN}-${PV}

DESCRIPTION="Framework for defining and tracking users, login sessions and seats."
HOMEPAGE="http://www.freedesktop.org/wiki/Software/ConsoleKit"
if [[ ${PV} = *p20* ]]; then
	        SRC_URI="http://ftp.osuosl.org/pub/funtoo/distfiles/${MY_P}.tar.xz"
else
	        SRC_URI="http://www.freedesktop.org/software/${MY_PN}/dist/${MY_P}.tar.bz2"
fi
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="acl debug doc kernel_linux pam policykit selinux test"

COMMON_DEPEND=">=dev-libs/dbus-glib-0.98
	>=dev-libs/glib-2.22
	sys-libs/zlib
	x11-libs/libX11
	acl? (
		sys-apps/acl
		virtual/udev
		)
	pam? ( virtual/pam )
	policykit? ( >=sys-auth/polkit-0.104-r1 )"
RDEPEND="${COMMON_DEPEND}
	kernel_linux? ( sys-apps/coreutils[acl?] )
	selinux? ( sec-policy/selinux-consolekit )"
DEPEND="${COMMON_DEPEND}
	dev-libs/libxslt
	virtual/pkgconfig
	doc? ( app-text/xmlto )
	test? (
		app-text/docbook-xml-dtd:4.1.2
		app-text/xmlto
		)"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	if use kernel_linux; then
		# This is from http://bugs.gentoo.org/376939
		use acl && CONFIG_CHECK="~TMPFS_POSIX_ACL"
		# This is required to get login-session-id string with pam_ck_connector.so
		use pam && CONFIG_CHECK+=" ~AUDITSYSCALL"
		linux-info_pkg_setup
	fi
}

src_prepare() {
	epatch \
		"${FILESDIR}"/${PN}-cleanup_console_tags.patch \
		"${FILESDIR}"/${PN}-shutdown-reboot-without-policies.patch \
		"${FILESDIR}"/${PN}-udev-acl-install_to_usr.patch \
		"${FILESDIR}"/${PN}-0.4.5-polkit-automagic.patch

	eautoreconf
}

src_configure() {
	local myconf
	[[ ${PV} = *p20* ]] && myconf='--enable-maintainer-mode'

	econf \
		XMLTO_FLAGS="--skip-validation" \
		--localstatedir="${EPREFIX}"/var \
		$(use_enable pam pam-module) \
		$(use_enable doc docbook-docs) \
		$(use_enable test docbook-docs) \
		$(use_enable debug) \
		$(use_enable policykit polkit) \
		$(use_enable acl udev-acl) \
		--with-dbus-services="${EPREFIX}"/usr/share/dbus-1/services \
		--with-pam-module-dir=$(getpam_mod_dir) \
		"$(systemd_with_unitdir)" \
		${myconf}
}

src_install() {
	emake \
		DESTDIR="${D}" \
		htmldocdir="${EPREFIX}"/usr/share/doc/${PF}/html \
		install

	dodoc AUTHORS HACKING NEWS README TODO

	newinitd "${FILESDIR}"/${PN}-0.2.rc consolekit

	keepdir /usr/lib/ConsoleKit/run-seat.d
	keepdir /usr/lib/ConsoleKit/run-session.d
	keepdir /etc/ConsoleKit/run-session.d
	keepdir /var/log/ConsoleKit

	exeinto /etc/X11/xinit/xinitrc.d
	newexe "${FILESDIR}"/90-consolekit-3 90-consolekit

	exeinto /usr/lib/ConsoleKit/run-session.d
	doexe "${FILESDIR}"/pam-foreground-compat.ck

	find "${ED}" -name '*.la' -exec rm -f {} +
}
