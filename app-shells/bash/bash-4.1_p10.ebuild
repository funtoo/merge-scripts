# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-shells/bash/bash-4.1_p10.ebuild,v 1.1 2011/02/28 18:25:36 vapier Exp $

EAPI="1"

inherit eutils flag-o-matic toolchain-funcs multilib

# Official patchlevel
# See ftp://ftp.cwru.edu/pub/bash/bash-3.2-patches/
PLEVEL=${PV##*_p}
MY_PV=${PV/_p*}
MY_PV=${MY_PV/_/-}
MY_P=${PN}-${MY_PV}
[[ ${PV} != *_p* ]] && PLEVEL=0
READLINE_VER=6.1
READLINE_PLEVEL=0 # both readline patches are also released as bash patches
patches() {
	local opt=$1 plevel=${2:-${PLEVEL}} pn=${3:-${PN}} pv=${4:-${MY_PV}}
	[[ ${plevel} -eq 0 ]] && return 1
	eval set -- {1..${plevel}}
	set -- $(printf "${pn}${pv/\.}-%03d " "$@")
	if [[ ${opt} == -s ]] ; then
		echo "${@/#/${DISTDIR}/}"
	else
		local u
		for u in ftp://ftp.cwru.edu/pub/bash mirror://gnu/${pn} ; do
			printf "${u}/${pn}-${pv}-patches/%s " "$@"
		done
	fi
}

DESCRIPTION="The standard GNU Bourne again shell"
HOMEPAGE="http://tiswww.case.edu/php/chet/bash/bashtop.html"
SRC_URI="mirror://gnu/bash/${MY_P}.tar.gz $(patches)
	$(patches ${READLINE_PLEVEL} readline ${READLINE_VER})"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"
IUSE="afs bashlogger examples mem-scramble +net nls plugins vanilla"

DEPEND=">=sys-libs/ncurses-5.2-r2
	nls? ( virtual/libintl )"
RDEPEND="${DEPEND}
	!<sys-apps/portage-2.1.7.16
	!<sys-apps/paludis-0.26.0_alpha5"

S=${WORKDIR}/${MY_P}

pkg_setup() {
	if is-flag -malign-double ; then #7332
		eerror "Detected bad CFLAGS '-malign-double'.  Do not use this"
		eerror "as it breaks LFS (struct stat64) on x86."
		die "remove -malign-double from your CFLAGS mr ricer"
	fi
	if use bashlogger ; then
		ewarn "The logging patch should ONLY be used in restricted (i.e. honeypot) envs."
		ewarn "This will log ALL output you enter into the shell, you have been warned."
	fi
}

src_unpack() {
	unpack ${MY_P}.tar.gz
	cd "${S}"

	# Include official patches
	[[ ${PLEVEL} -gt 0 ]] && epatch $(patches -s)
	cd lib/readline
	[[ ${READLINE_PLEVEL} -gt 0 ]] && epatch $(patches -s ${READLINE_PLEVEL} readline ${READLINE_VER})
	cd ../..

	epatch "${FILESDIR}"/${PN}-4.1-fbsd-eaccess.patch #303411

	if ! use vanilla ; then
		sed -i '1i#define NEED_FPURGE_DECL' execute_cmd.c # needs fpurge() decl
		epatch "${FILESDIR}"/${PN}-4.1-parallel-build.patch
	fi
}

src_compile() {
	local myconf=

	# For descriptions of these, see config-top.h
	# bashrc/#26952 bash_logout/#90488 ssh/#24762
	append-cppflags \
		-DDEFAULT_PATH_VALUE=\'\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"\' \
		-DSTANDARD_UTILS_PATH=\'\"/bin:/usr/bin:/sbin:/usr/sbin\"\' \
		-DSYS_BASHRC=\'\"/etc/bash/bashrc\"\' \
		-DSYS_BASH_LOGOUT=\'\"/etc/bash/bash_logout\"\' \
		-DNON_INTERACTIVE_LOGIN_SHELLS \
		-DSSH_SOURCE_BASHRC \
		$(use bashlogger && echo -DSYSLOG_HISTORY)

	# Always use the buildin readline, else if we update readline
	# bash gets borked as readline is usually not binary compadible
	# between minor versions.
	#myconf="${myconf} $(use_with !readline installed-readline)"
	myconf="${myconf} --without-installed-readline"

	# Don't even think about building this statically without
	# reading Bug 7714 first.  If you still build it statically,
	# don't come crying to us with bugs ;).
	#use static && export LDFLAGS="${LDFLAGS} -static"
	use nls || myconf="${myconf} --disable-nls"

	# Force linking with system curses ... the bundled termcap lib
	# sucks bad compared to ncurses
	myconf="${myconf} --with-curses"

	myconf="${myconf} --without-lispdir" #335896

	use plugins && append-ldflags -Wl,-rpath,/usr/$(get_libdir)/bash
	econf \
		$(use_with afs) \
		$(use_enable net net-redirections) \
		--disable-profiling \
		$(use_enable mem-scramble) \
		$(use_with mem-scramble bash-malloc) \
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
