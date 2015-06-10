# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils git-2 linux-info pam

MY_PN=ConsoleKit2

EGIT_REPO_URI="https://github.com/${MY_PN}/${MY_PN}.git"
EGIT_COMMIT="90716a777a1b55970cee630c83d870bc0e76e8ab"
DESCRIPTION="Framework for defining and tracking users, login sessions and seats"
HOMEPAGE="http://github.com/ConsoleKit2/ConsoleKit2 http://www.freedesktop.org/wiki/Software/ConsoleKit"
SRC_URI="https://github.com/${MY_PN}/${MY_PN}/archive/${EGIT_COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="acl debug doc kernel_linux pam policykit selinux test"

COMMON_DEPEND=">=dev-libs/dbus-glib-0.100
	>=dev-libs/glib-2.38.2-r1:2
	sys-libs/zlib
	x11-libs/libX11
	acl? (
		sys-apps/acl
		>=virtual/udev-200
		)
	pam? ( virtual/pam )
	policykit? ( >=sys-auth/polkit-0.110 )"
RDEPEND="${COMMON_DEPEND}
	kernel_linux? ( sys-apps/coreutils[acl?] )
	selinux? ( sec-policy/selinux-consolekit )
	pam? ( >=sys-auth/pambase-20150213-r2 )"
DEPEND="${COMMON_DEPEND}
	dev-libs/libxslt
	virtual/pkgconfig
	doc? ( app-text/xmlto )
	test? (
		app-text/docbook-xml-dtd:4.1.2
		app-text/xmlto
		)"

S=${WORKDIR}

QA_MULTILIB_PATHS="usr/lib/ConsoleKit/.*"

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
	sed -i -e '/SystemdService/d' data/org.freedesktop.ConsoleKit.service.in || die
}

src_configure() {
	econf \
		XMLTO_FLAGS='--skip-validation' \
		--libexecdir="${EPREFIX}"/usr/lib/ConsoleKit \
		--localstatedir="${EPREFIX}"/var \
		$(use_enable pam pam-module) \
		$(use_enable doc docbook-docs) \
		$(use_enable test docbook-docs) \
		$(use_enable debug) \
		$(use_enable policykit polkit) \
		$(use_enable acl udev-acl) \
		--with-dbus-services="${EPREFIX}"/usr/share/dbus-1/services \
		--with-pam-module-dir="$(getpam_mod_dir)" \
		--with-logrotate-dir=/etc/logrotate.d \
		--with-xinitrc-dir=/etc/X11/xinit/xinitrc.d \
		--without-systemdsystemunitdir
}

src_install() {
	emake \
		DESTDIR="${D}" \
		htmldocdir="${EPREFIX}"/usr/share/doc/${PF}/html \
		install

	dosym /usr/lib/ConsoleKit /usr/lib/${PN}

	dodoc AUTHORS HACKING NEWS README TODO

	newinitd "${FILESDIR}"/${PN}-0.2.rc consolekit

	keepdir /usr/lib/ConsoleKit/run-seat.d
	keepdir /usr/lib/ConsoleKit/run-session.d
	keepdir /etc/ConsoleKit/run-session.d
	keepdir /var/log/ConsoleKit

	exeinto /etc/X11/xinit/xinitrc.d
	newexe "${FILESDIR}"/90-consolekit-3 90-consolekit

	prune_libtool_files --all # --all for pam_ck_connector.la

	rm -rf "${ED}"/var/run # let the init script create the directory

	insinto /etc/logrotate.d
	newins "${WORKDIR}"/debian/${PN}.logrotate ${PN} #374513
}
