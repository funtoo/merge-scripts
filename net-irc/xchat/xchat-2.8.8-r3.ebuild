# Distributed under the terms of the GNU General Public License v2

EAPI=3

inherit eutils versionator gnome2 autotools

DESCRIPTION="Graphical IRC client"
# Icons are from http://half-left.deviantart.com/art/XChat-IRC-Icon-200804640
SRC_URI="http://www.xchat.org/files/source/$(get_version_component_range 1-2)/${P}.tar.bz2
	mirror://sourceforge/${PN}/${P}.tar.bz2
	hires-icons? ( http://dev.gentoo.org/~nirbheek/dist/xchat_irc_icon_by_half_left-d3bjxuo.zip )
	xchatdccserver? ( mirror://gentoo/${PN}-dccserver-0.6.patch.bz2 )"
HOMEPAGE="http://www.xchat.org/"

LICENSE="GPL-2 hires-icons? ( GPL-3 )"
SLOT="2"
KEYWORDS="* ~*"
IUSE="dbus fastscroll +gtk hires-icons ipv6 libnotify mmx nls ntlm perl python spell ssl tcl xchatdccserver"

RDEPEND=">=dev-libs/glib-2.6.0:2
	gtk? ( >=x11-libs/gtk+-2.10.0:2 )
	ssl? ( >=dev-libs/openssl-0.9.6d )
	perl? ( >=dev-lang/perl-5.8.0 )
	python? ( =dev-lang/python-2* )
	tcl? ( dev-lang/tcl )
	dbus? ( >=dev-libs/dbus-glib-0.71 )
	spell? ( app-text/gtkspell:2 )
	libnotify? ( x11-libs/libnotify )
	ntlm? ( net-libs/libntlm )
	x11-libs/pango
	!<net-irc/xchat-gnome-0.9"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	nls? ( sys-devel/gettext )"

pkg_setup() {
	# Added for to fix a sparc seg fault issue by Jason Wever <weeve@gentoo.org>
	if [[ ${ARCH} = sparc ]] ; then
		replace-flags "-O[3-9]" "-O2"
	fi
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-input-box4.patch \
		"${FILESDIR}"/${PN}-2.8.4-interix.patch \
		"${FILESDIR}"/${P}-libnotify07.patch \
		"${FILESDIR}"/${P}-dbus.patch \
		"${FILESDIR}"/${PN}-2.8.8-cflags.patch \
		"${FILESDIR}"/${P}-glib-2.31.patch \
		"${FILESDIR}"/xchat-glib.patch

	use xchatdccserver && epatch "${DISTDIR}"/xchat-dccserver-0.6.patch.bz2

	# use libdir/xchat/plugins as the plugin directory
	if [ $(get_libdir) != "lib" ] ; then
		sed -i -e 's:${prefix}/lib/xchat:${libdir}/xchat:' \
			"${S}"/configure.in || die
	fi

	# xchat sourcecode ships with po/Makefile.in.in from gettext-0.17
	# which fails with >=gettext-0.18
	cp "${EPREFIX}"/usr/share/gettext/po/Makefile.in.in "${S}"/po/ || die

	eautoreconf
}

src_configure() {
	# xchat's configure script uses sys.path to find library path
	# instead of python-config (#25943)
	unset PYTHONPATH

	if [[ ${CHOST} == *-interix* ]]; then
		# this -Wl,-E option for the interix ld makes some checks
		# false positives, so set those here.
		export ac_cv_func_strtoull=no
		export ac_cv_func_memrchr=no
	fi

	econf \
		--enable-shm \
		$(use_enable dbus) \
		$(use_enable ipv6) \
		$(use_enable mmx) \
		$(use_enable nls) \
		$(use_enable ntlm) \
		$(use_enable perl) \
		$(use_enable python) \
		$(use_enable spell spell gtkspell) \
		$(use_enable ssl openssl) \
		$(use_enable tcl) \
		$(use_enable gtk gtkfe) \
		$(use_enable !gtk textfe) \
		$(use_enable fastscroll xft)
}

src_install() {
	USE_DESTDIR=1 gnome2_src_install || die "make install failed"

	# install plugin development header
	insinto /usr/include/xchat
	doins src/common/xchat-plugin.h || die "doins failed"

	dodoc ChangeLog README* || die "dodoc failed"

	if use hires-icons; then
		cd "${WORKDIR}/XChat-Icon/apps"
		for i in *; do
			insinto "/usr/share/icons/hicolor/${i}/apps"
			doins "${i}/xchat.png"
		done
		# Replace default pixmap icon
		cp "48x48/xchat.png" "${D}/usr/share/pixmaps" || die
	fi

	# remove useless desktop entry when gtk USE flag is unset
	if ! use gtk ; then
		rm "${ED}"/usr/share/applications -rf
	fi

	# Don't install .la files
	find "${ED}" -name '*.la' -delete
}

pkg_postinst() {
	if use gtk ; then
		elog
		elog "XChat binary has been renamed from xchat-2 to xchat."
		elog

		if has_version net-irc/xchat-systray
		then
			elog "XChat now includes it's own systray icon, you may want to remove net-irc/xchat-systray."
			elog
		fi
	else
		elog "You have disabled the gtk USE flag. This means you don't have"
		elog "the GTK-GUI for xchat but only a text interface called \"xchat-text\"."
	fi

	gnome2_icon_cache_update
}

