# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-shells/bash/bash-3.2_p51.ebuild,v 1.1 2010/05/20 03:00:49 vapier Exp $

EAPI=1

inherit eutils flag-o-matic toolchain-funcs multilib

# Official patchlevel
# See ftp://ftp.cwru.edu/pub/bash/bash-3.2-patches/
PLEVEL=${PV##*_p}
MY_PV=${PV/_p*}
MY_P=${PN}-${MY_PV}
READLINE_VER=5.2
READLINE_PLEVEL=0 # both readline patches are also released as bash patches

DESCRIPTION="The standard GNU Bourne again shell"
HOMEPAGE="http://tiswww.case.edu/php/chet/bash/bashtop.html"
SRC_URI="mirror://gnu/bash/${MY_P}.tar.gz
	ftp://ftp.cwru.edu/pub/bash/${MY_P}.tar.gz
	$(for ((i=1; i<=PLEVEL; i++)); do
		printf 'ftp://ftp.cwru.edu/pub/bash/bash-%s-patches/bash%s-%03d\n' \
			${MY_PV} ${MY_PV/\.} ${i}
		printf 'mirror://gnu/bash/bash-%s-patches/bash%s-%03d\n' \
			${MY_PV} ${MY_PV/\.} ${i}
	done)
	$(for ((i=1; i<=READLINE_PLEVEL; i++)); do
		printf 'ftp://ftp.cwru.edu/pub/bash/readline-%s-patches/readline%s-%03d\n' \
			${READLINE_VER} ${READLINE_VER/\.} ${i}
		printf 'mirror://gnu/bash/readline-%s-patches/readline%s-%03d\n' \
			${READLINE_VER} ${READLINE_VER/\.} ${i}
	done)"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"
IUSE="afs bashlogger examples +net nls plugins vanilla"

DEPEND=">=sys-libs/ncurses-5.2-r2
	nls? ( virtual/libintl )"
RDEPEND="${DEPEND}
	!<sys-apps/portage-2.1.5
	!<sys-apps/paludis-0.26.0_alpha5"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	if is-flag -malign-double ; then #7332
		eerror "Detected bad CFLAGS '-malign-double'.  Do not use this"
		eerror "as it breaks LFS (struct stat64) on x86."
		die "remove -malign-double from your CFLAGS mr ricer"
	fi
}

src_unpack() {
	unpack ${MY_P}.tar.gz
	cd "${S}"

	# Include official patches
	local i
	for ((i=1; i<=PLEVEL; i++)); do
		epatch "${DISTDIR}"/${PN}${MY_PV/\.}-$(printf '%03d' ${i})
	done
	cd lib/readline
	for ((i=1; i<=READLINE_PLEVEL; i++)); do
		epatch "${DISTDIR}"/readline${READLINE_VER/\.}-$(printf '%03d' ${i})
	done
	cd ../..

	if ! use vanilla ; then
		epatch "${FILESDIR}"/autoconf-mktime-2.59.patch #220040
		epatch "${FILESDIR}"/${PN}-3.1-gentoo.patch
		epatch "${FILESDIR}"/${PN}-3.2-loadables.patch
		epatch "${FILESDIR}"/${PN}-3.2-protos.patch
		epatch "${FILESDIR}"/${PN}-3.2-session-leader.patch #231775
		epatch "${FILESDIR}"/${PN}-3.2-parallel-build.patch #189671
		epatch "${FILESDIR}"/${PN}-3.2-ldflags-for-build.patch #211947

		# Fix process substitution on BSD.
		epatch "${FILESDIR}"/${PN}-3.2-process-subst.patch

		epatch "${FILESDIR}"/${PN}-3.2-ulimit.patch
		# Don't barf on handled signals in scripts
		epatch "${FILESDIR}"/${PN}-3.0-trap-fg-signals.patch
		epatch "${FILESDIR}"/${PN}-3.2-dev-fd-test-as-user.patch #131875
		# Log bash commands to syslog #91327
		if use bashlogger ; then
			echo
			ewarn "The logging patch should ONLY be used in restricted (i.e. honeypot) envs."
			ewarn "This will log ALL output you enter into the shell, you have been warned."
			ebeep
			epause
			epatch "${FILESDIR}"/${PN}-3.1-bash-logger.patch
		fi
	fi

	epatch "${FILESDIR}"/${PN}-3.0-configs.patch
}

src_compile() {
	local myconf=

	# Always use the buildin readline, else if we update readline
	# bash gets borked as readline is usually not binary compadible
	# between minor versions.
	#myconf="${myconf} $(use_with !readline installed-readline)"
	myconf="${myconf} --without-installed-readline"

	# Don't even think about building this statically without
	# reading Bug 7714 first.  If you still build it statically,
	# don't come crying to use with bugs ;).
	#use static && export LDFLAGS="${LDFLAGS} -static"
	use nls || myconf="${myconf} --disable-nls"

	# Force linking with system curses ... the bundled termcap lib
	# sucks bad compared to ncurses
	myconf="${myconf} --with-curses"

	# Default path is to use /usr/local/..... regardless.  This little
	# magic will set the default path to /usr/..... and keep us from
	# worrying about the rest of the path getting out of sync with the
	# ebuild code.
	eval $(echo export $(ac_default_prefix=/usr; eval echo $(grep DEBUGGER_START_FILE= configure)))

	use plugins && append-ldflags -Wl,-rpath,/usr/$(get_libdir)/bash
	econf \
		$(use_with afs) \
		$(use_enable net net-redirections) \
		--disable-profiling \
		--without-gnu-malloc \
		${myconf} || die
	emake || die "make failed"

	if use plugins ; then
		emake -C examples/loadables all others || die
	fi
}

src_install() {
	emake install DESTDIR="${D}" || die

	dodir /bin
	mv "${D}"/usr/bin/bash "${D}"/bin/ || die
	dosym bash /bin/rbash

	insinto /etc/bash
	doins "${FILESDIR}"/{bashrc,bash_logout}
	insinto /etc/skel
	for f in bash{_logout,_profile,rc} ; do
		newins "${FILESDIR}"/dot-${f} .${f}
	done

	sed -i -e "s:#${USERLAND}#@::" "${D}"/etc/skel/.bashrc "${D}"/etc/bash/bashrc
	sed -i -e '/#@/d' "${D}"/etc/skel/.bashrc "${D}"/etc/bash/bashrc

	if use plugins ; then
		exeinto /usr/$(get_libdir)/bash
		doexe $(echo examples/loadables/*.o | sed 's:\.o::g') || die
	fi

	if use examples ; then
		for d in examples/{functions,misc,scripts,scripts.noah,scripts.v2} ; do
			exeinto /usr/share/doc/${PF}/${d}
			insinto /usr/share/doc/${PF}/${d}
			for f in ${d}/* ; do
				if [[ ${f##*/} != PERMISSION ]] && [[ ${f##*/} != *README ]] ; then
					doexe ${f}
				else
					doins ${f}
				fi
			done
		done
	fi

	doman doc/*.1
	dodoc README NEWS AUTHORS CHANGES COMPAT Y2K doc/FAQ doc/INTRO
	dosym bash.info /usr/share/info/bashref.info
}

pkg_preinst() {
	if [[ -e ${ROOT}/etc/bashrc ]] && [[ ! -d ${ROOT}/etc/bash ]] ; then
		mkdir -p "${ROOT}"/etc/bash
		mv -f "${ROOT}"/etc/bashrc "${ROOT}"/etc/bash/
	fi

	if [[ -L ${ROOT}/bin/sh ]]; then
		# rewrite the symlink to ensure that its mtime changes. having /bin/sh
		# missing even temporarily causes a fatal error with paludis.
		local target=$(readlink "${ROOT}"/bin/sh)
		ln -sf "${target}" "${ROOT}"/bin/sh
	fi
}

pkg_postinst() {
	# If /bin/sh does not exist, provide it
	if [[ ! -e ${ROOT}/bin/sh ]]; then
		ln -sf bash "${ROOT}"/bin/sh
	fi
}
