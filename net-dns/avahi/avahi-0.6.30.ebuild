# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-dns/avahi/avahi-0.6.30.ebuild,v 1.2 2011/08/06 09:41:21 zmedico Exp $

EAPI="3"

PYTHON_DEPEND="python? 2"
PYTHON_USE_WITH="gdbm"
PYTHON_USE_WITH_OPT="python"

inherit eutils mono python multilib flag-o-matic

DESCRIPTION="System which facilitates service discovery on a local network"
HOMEPAGE="http://avahi.org/"
SRC_URI="http://avahi.org/download/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd ~x86-linux"
IUSE="autoipd bookmarks dbus doc gdbm gtk howl-compat ipv6 kernel_linux mdnsresponder-compat mono python qt4 test "

DBUS_DEPEND=">=sys-apps/dbus-0.30"
RDEPEND=">=dev-libs/libdaemon-0.14
	dev-libs/expat
	>=dev-libs/glib-2
	gdbm? ( sys-libs/gdbm )
	qt4? ( x11-libs/qt-core:4 )
	gtk? (
		>=x11-libs/gtk+-2.14.0:2
	)
	dbus? (
		${DBUS_DEPEND}
		python? ( dev-python/dbus-python )
	)
	mono? (
		>=dev-lang/mono-1.1.10
		gtk? ( >=dev-dotnet/gtk-sharp-2 )
	)
	howl-compat? (
		!net-misc/howl
		${DBUS_DEPEND}
	)
	mdnsresponder-compat? (
		!net-misc/mDNSResponder
		${DBUS_DEPEND}
	)
	python? (
		gtk? ( >=dev-python/pygtk-2 )
	)
	bookmarks? (
		dev-python/twisted
		dev-python/twisted-web
	)
	kernel_linux? ( sys-libs/libcap )"
DEPEND="${RDEPEND}
	>=dev-util/intltool-0.40.5
	>=dev-util/pkgconfig-0.9.0
	doc? (
		app-doc/doxygen
		mono? ( >=virtual/monodoc-1.1.8 )
	)"

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi

	if use python && ! use dbus && ! use gtk; then
		ewarn "For proper python support you should also enable the dbus and gtk USE flags!"
	fi
}

pkg_preinst() {
	enewgroup netdev
	enewgroup avahi
	enewuser avahi -1 -1 -1 avahi

	if use autoipd; then
		enewgroup avahi-autoipd
		enewuser avahi-autoipd -1 -1 -1 avahi-autoipd
	fi
}

src_prepare() {
	if use ipv6; then
		sed -i \
			-e s/use-ipv6=no/use-ipv6=yes/ \
			avahi-daemon/avahi-daemon.conf || die
	fi

	sed -i\
		-e "s:\\.\\./\\.\\./\\.\\./doc/avahi-docs/html/:../../../doc/${PF}/html/:" \
		doxygen_to_devhelp.xsl || die
}

src_configure() {
	use sh && replace-flags -O? -O0

	local myconf=""

	if use python; then
		myconf+="
			$(use_enable dbus python-dbus)
			$(use_enable gtk pygtk)
		"
	fi

	if use mono; then
		myconf+=" $(use_enable doc monodoc)"
	fi

	# these require dbus enabled
	if use mdnsresponder-compat || use howl-compat || use mono; then
		myconf+=" --enable-dbus"
	fi

	# We need to unset DISPLAY, else the configure script might have problems detecting the pygtk module
	unset DISPLAY

	# Upstream ships a gir file (AvahiCore.gir) which does not work with
	# >=gobject-introspection-0.9, so we disable introspection for now.
	# http://avahi.org/ticket/318
	econf \
		--localstatedir="${EPREFIX}/var" \
		--with-distro=gentoo \
		--disable-python-dbus \
		--disable-pygtk \
		--disable-xmltoman \
		--disable-monodoc \
		--disable-introspection \
		--enable-glib \
		$(use_enable test tests) \
		$(use_enable autoipd) \
		$(use_enable mdnsresponder-compat compat-libdns_sd) \
		$(use_enable howl-compat compat-howl) \
		$(use_enable doc doxygen-doc) \
		$(use_enable mono) \
		$(use_enable dbus) \
		$(use_enable python) \
		--disable-gtk3 \
		$(use_enable gtk) \
		--disable-qt3 \
		$(use_enable qt4) \
		$(use_enable gdbm) \
		${myconf}
}

src_compile() {
	emake || die "emake failed"

	use doc && { emake avahi.devhelp || die ; }
}

src_install() {
	emake install py_compile=true DESTDIR="${D}" || die "make install failed"
	use bookmarks && use python && use dbus && use gtk || \
		rm -f "${ED}"/usr/bin/avahi-bookmarks

	use howl-compat && ln -s avahi-compat-howl.pc "${ED}"/usr/$(get_libdir)/pkgconfig/howl.pc
	use mdnsresponder-compat && ln -s avahi-compat-libdns_sd/dns_sd.h "${ED}"/usr/include/dns_sd.h

	if use autoipd; then
		insinto /$(get_libdir)/rcscripts/net
		doins "${FILESDIR}"/autoipd.sh || die

		insinto /$(get_libdir)/rc/net
		newins "${FILESDIR}"/autoipd-openrc.sh autoipd.sh || die
	fi

	dodoc docs/{AUTHORS,NEWS,README,TODO} || die

	if use doc; then
		dohtml -r doxygen/html/. || die
		insinto /usr/share/devhelp/books/avahi
		doins avahi.devhelp || die
	fi
}

pkg_postrm() {
	use python && python_mod_cleanup avahi $(use dbus && use gtk && echo avahi_discover)
}

pkg_postinst() {
	use python && python_mod_optimize avahi $(use dbus && use gtk && echo avahi_discover)

	if use autoipd; then
		echo
		elog "To use avahi-autoipd to configure your interfaces with IPv4LL (RFC3927)"
		elog "addresses, just set config_<interface>=( autoipd ) in /etc/conf.d/net!"
	fi

	if use dbus; then
		echo
		elog "If this is your first install of avahi please reload your dbus config"
		elog "with /etc/init.d/dbus reload before starting avahi-daemon!"
	fi
}
