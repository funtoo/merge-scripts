# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-shells/bash/bash-3.1_p17.ebuild,v 1.21 2009/11/11 04:15:27 vapier Exp $

inherit eutils flag-o-matic toolchain-funcs

# Official patchlevel
# See ftp://ftp.cwru.edu/pub/bash/bash-3.1-patches/
PLEVEL=${PV##*_p}
MY_PV=${PV/_p*}
MY_P=${PN}-${MY_PV}
READLINE_VER=5.1
READLINE_PLEVEL=1

DESCRIPTION="The standard GNU Bourne again shell"
HOMEPAGE="http://tiswww.case.edu/php/chet/bash/bashtop.html"
# Hit the GNU mirrors before hitting Chet's site
#		printf 'mirror://gnu/bash/bash-%s-patches/bash%s-%03d\n' \
#			${MY_PV} ${MY_PV/\.} ${i}
SRC_URI="mirror://gnu/bash/${MY_P}.tar.gz
	ftp://ftp.cwru.edu/pub/bash/${MY_P}.tar.gz
	$(for ((i=1; i<=PLEVEL; i++)); do
		printf 'ftp://ftp.cwru.edu/pub/bash/bash-%s-patches/bash%s-%03d\n' \
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
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE="afs bashlogger nls vanilla"

DEPEND=">=sys-libs/ncurses-5.2-r2
	nls? ( virtual/libintl )"
RDEPEND=${DEPEND}

S=${WORKDIR}/${MY_P}

src_unpack() {
	unpack ${MY_P}.tar.gz
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-3.1-gentoo.patch

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
		# Fall back to /etc/inputrc
		epatch "${FILESDIR}"/${PN}-3.0-etc-inputrc.patch
		# Add more ulimit options (from Fedora)
		epatch "${FILESDIR}"/${MY_P}-ulimit.patch
		# Fix a memleak in read_builtin (from Fedora)
		epatch "${FILESDIR}"/${PN}-3.0-read-memleak.patch
		# Don't barf on handled signals in scripts
		epatch "${FILESDIR}"/${PN}-3.0-trap-fg-signals.patch
		# Fix -/bin/bash login shell #118257
		epatch "${FILESDIR}"/bash-3.1-fix-dash-login-shell.patch
		# Fix /dev/fd test with FEATURES=userpriv #131875
		epatch "${FILESDIR}"/bash-3.1-dev-fd-test-as-user.patch
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
	filter-flags -malign-double

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

	econf \
		$(use_with afs) \
		--disable-profiling \
		--without-gnu-malloc \
		${myconf} || die
	emake -j1 || die "make failed"	# see bug 102426
}

src_install() {
	einstall || die

	dodir /bin
	mv "${D}"/usr/bin/bash "${D}"/bin/
	[[ ${USERLAND} != "BSD" ]] && dosym bash /bin/sh
	dosym bash /bin/rbash

	insinto /etc/bash
	doins "${FILESDIR}"/{bashrc,bash_logout}
	insinto /etc/skel
	for f in bash{_logout,_profile,rc} ; do
		newins "${FILESDIR}"/dot-${f} .${f}
	done

	sed -i -e "s:#${USERLAND}#@::" "${D}"/etc/skel/.bashrc "${D}"/etc/bash/bashrc
	sed -i -e '/#@/d' "${D}"/etc/skel/.bashrc "${D}"/etc/bash/bashrc

	doman doc/*.1
	dodoc README NEWS AUTHORS CHANGES COMPAT Y2K doc/FAQ doc/INTRO
	dosym bash.info.gz /usr/share/info/bashref.info.gz
}

pkg_preinst() {
	if [[ -e ${ROOT}/etc/bashrc ]] && [[ ! -d ${ROOT}/etc/bash ]] ; then
		mkdir -p "${ROOT}"/etc/bash
		mv -f "${ROOT}"/etc/bashrc "${ROOT}"/etc/bash/
	fi

	# our bash_logout is just a place holder so dont
	# force users to go through etc-update all the time
	if [[ -e ${ROOT}/etc/bash/bash_logout ]] ; then
		rm -f "${D}"/etc/bash/bash_logout
	fi
}
