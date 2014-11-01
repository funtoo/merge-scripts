# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit autotools eutils flag-o-matic pam toolchain-funcs user

DESCRIPTION="Full-screen window manager that multiplexes physical terminals between several processes"
HOMEPAGE="http://www.gnu.org/software/screen/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="debug nethack pam selinux multiuser"

CDEPEND=">=sys-libs/ncurses-5.2
	pam? ( virtual/pam )"
RDEPEND="${CDEPEND}
	selinux? ( sec-policy/selinux-screen )"
DEPEND="${CDEPEND}
	sys-apps/texinfo"

pkg_setup() {
	# Make sure utmp group exists, as it's used later on.
	enewgroup utmp 406
}

src_prepare() {
	# Don't use utempter even if it is found on the system
	epatch "${FILESDIR}"/4.0.2-no-utempter.patch

	# sched.h is a system header and causes problems with some C libraries
	mv sched.h _sched.h || die
	sed -i '/include/ s:sched.h:_sched.h:' screen.h || die

	# Fix manpage.
	sed -i \
		-e "s:/usr/local/etc/screenrc:${EPREFIX}/etc/screenrc:g" \
		-e "s:/usr/local/screens:${EPREFIX}/tmp/screen:g" \
		-e "s:/local/etc/screenrc:${EPREFIX}/etc/screenrc:g" \
		-e "s:/etc/utmp:${EPREFIX}/var/run/utmp:g" \
		-e "s:/local/screens/S-:${EPREFIX}/tmp/screen/S-:g" \
		doc/screen.1 \
		|| die

	# reconfigure
	eautoreconf
}

src_configure() {
	append-cppflags "-DMAXWIN=${MAX_SCREEN_WINDOWS:-100}"

	if [[ ${CHOST} == *-solaris* ]] ; then
		# https://lists.gnu.org/archive/html/screen-devel/2014-04/msg00095.html
		append-cppflags -D_XOPEN_SOURCE \
			-D_XOPEN_SOURCE_EXTENDED=1 \
			-D__EXTENSIONS__
		append-libs -lsocket -lnsl
	fi

	use nethack || append-cppflags "-DNONETHACK"
	use debug && append-cppflags "-DDEBUG"

	econf \
		--with-sys-screenrc="${EPREFIX}/etc/screenrc" \
		--with-pty-mode=0620 \
		--with-pty-group=5 \
		--enable-rxvt_osc \
		--enable-telnet \
		--enable-colors256 \
		$(use_enable pam)
}

src_compile() {
	LC_ALL=POSIX emake comm.h term.h
	emake osdef.h

	emake -C doc screen.info
	default
}

src_install() {
	local tmpfiles_perms tmpfiles_group

	dobin screen

	if use multiuser || use prefix
	then
		fperms 4755 /usr/bin/screen
		tmpfiles_perms="0755"
		tmpfiles_group="root"
	else
		fowners root:utmp /usr/bin/screen
		fperms 2755 /usr/bin/screen
		tmpfiles_perms="0775"
		tmpfiles_group="utmp"
	fi

	insinto /usr/share/screen
	doins terminfo/{screencap,screeninfo.src}
	insinto /usr/share/screen/utf8encodings
	doins utf8encodings/??
	insinto /etc
	doins "${FILESDIR}"/screenrc

	pamd_mimic_system screen auth

	dodoc \
		README ChangeLog INSTALL TODO NEWS* patchlevel.h \
		doc/{FAQ,README.DOTSCREEN,fdpat.ps,window_to_display.ps}

	doman doc/screen.1
	doinfo doc/screen.info
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]]
	then
		elog "Some dangerous key bindings have been removed or changed to more safe values."
		elog "We enable some xterm hacks in our default screenrc, which might break some"
		elog "applications. Please check /etc/screenrc for information on these changes."
	fi
}
