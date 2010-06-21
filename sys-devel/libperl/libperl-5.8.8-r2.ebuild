# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/libperl/libperl-5.8.8-r2.ebuild,v 1.14 2010/03/31 18:48:44 armin76 Exp $

# The basic theory based on comments from Daniel Robbins <drobbins@gentoo.org>.
#
# We split the perl ebuild into libperl and perl.  The layout is as follows:
#
# libperl:
#
#  This is a slotted (SLOT=[0-9]*) ebuild, meaning we should be able to have a
#  few versions that are not binary compadible installed.
#
#  How we get libperl.so multi-versioned, is by adding to the link command:
#
#    -Wl,-soname -Wl,libperl.so.`echo $(LIBPERL) | cut -d. -f3`
#
#  This gives us:
#
#    $(LIBPERL): $& perl$(OBJ_EXT) $(obj) $(LIBPERLEXPORT)
#        $(LD) -o $@ $(SHRPLDFLAGS) perl$(OBJ_EXT) $(obj) \
#              -Wl,-soname -Wl,libperl.so.`echo $(LIBPERL) | cut -d. -f3`
#
#  We then configure perl with LIBPERL set to:
#
#    LIBPERL="libperl.so.${SLOT}.`echo ${PV} | cut -d. -f1,2`"
#
#  Or with the variables defined in this ebuild:
#
#    LIBPERL="libperl.so.${PERLSLOT}.${SHORT_PV}"
#
#  The result is that our 'soname' is 'libperl.so.${PERLSLOT}' (at the time of
#  writing this for perl-5.8.0, 'libperl.so.1'), causing all apps that is linked
#  to libperl to link to 'libperl.so.${PERLSLOT}'.
#
#  If a new perl version, perl-z.y.z comes out that have a libperl not binary
#  compatible with the previous version, we just keep the previous libperl
#  installed, and all apps linked to it will still be able to use:
#
#    libperl.so.${PERLSLOT}'
#
#  while the new ones will link to:
#
#    libperl.so.$((PERLSLOT+1))'
#
# perl:
#
#  Not much to this one.  It compiles with a static libperl.a, and are unslotted
#  (meaning SLOT=0).  We thus always have the latest *stable* perl version
#  installed, with corrisponding version of libperl.  The perl ebuild will of
#  course DEPEND on libperl.
#
# Martin Schlemmer <azarah@gentoo.org> (28 Dec 2002).

IUSE="berkdb debug gdbm ithreads"

inherit eutils flag-o-matic toolchain-funcs multilib

# The slot of this binary compat version of libperl.so
PERLSLOT="1"

SHORT_PV="${PV%.*}"
MY_P="perl-${PV/_rc/-RC}"
S="${WORKDIR}/${MY_P}"
DESCRIPTION="Larry Wall's Practical Extraction and Reporting Language"
SRC_URI="mirror://cpan/src/${MY_P}.tar.bz2"
HOMEPAGE="http://www.perl.org"
SLOT="${PERLSLOT}"
LIBPERL="libperl$(get_libname ${PERLSLOT}.${SHORT_PV})"
LICENSE="|| ( Artistic GPL-1 GPL-2 GPL-3 )"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"

# rac 2004.08.06

# i am not kidding here. you will forkbomb yourself out of existence
# because make check -n wants to make miniperl, which runs itself at
# the very end to make sure it's working right. this behaves very
# badly when you -n it, because it won't exist and will therefore try
# to build itself again ad infinitum.

RESTRICT="test"

DEPEND="berkdb? ( sys-libs/db )
	gdbm? ( >=sys-libs/gdbm-1.8.0 )
	elibc_FreeBSD? ( sys-freebsd/freebsd-mk-defs )"

RDEPEND="
	berkdb? ( sys-libs/db )
	gdbm? ( >=sys-libs/gdbm-1.8.0 )"

PDEPEND="~dev-lang/perl-${PV}"

pkg_setup() {
	# I think this should rather be displayed if you *have* 'ithreads'
	# in USE if it could break things ...
	if use ithreads
	then
		ewarn ""
		ewarn "PLEASE NOTE: You are compiling perl-5.8 with"
		ewarn "interpreter-level threading enabled."
		ewarn "Threading is not supported by all applications "
		ewarn "that compile against perl. You use threading at "
		ewarn "your own discretion. "
		ewarn ""
		epause 10
	fi
}

src_unpack() {

	unpack ${A}

	# Fix the build scripts to create libperl with a soname of ${SLOT}.
	# We basically add:
	#
	#   -Wl,-soname -Wl,libperl.so.`echo $(LIBPERL) | cut -d. -f3`
	#
	# to the line that links libperl.so, and then set LIBPERL to:
	#
	#   LIBPERL=libperl.so.${SLOT}.`echo ${PV} | cut -d. -f1,2`
	#
	cd "${S}";
	epatch "${FILESDIR}"/${PN}-create-libperl-soname.patch

	# Configure makes an unwarranted assumption that /bin/ksh is a
	# good shell. This patch makes it revert to using /bin/sh unless
	# /bin/ksh really is executable. Should fix bug 42665.
	# rac 2004.06.09
	cd "${S}"; epatch "${FILESDIR}"/${PN}-noksh.patch

	# we need the same @INC-inversion magic here we do in perl
	cd "${S}"; epatch "${FILESDIR}"/${P}-reorder-INC.patch

	# makedepend.SH contains a syntax error which is ignored by bash but causes
	# dash to abort
	epatch "${FILESDIR}"/${P}-makedepend-syntax.patch

	# On PA7200, uname -a contains a single quote and we need to
	# filter it otherwise configure fails. See #125535.
	epatch "${FILESDIR}"/perl-hppa-pa7200-configure.patch

	use amd64 || use ppc64 && cd "${S}" && epatch "${FILESDIR}"/${P}-lib64.patch
	[[ ${CHOST} == *-dragonfly* ]] && cd "${S}" && epatch "${FILESDIR}"/${P}-dragonfly-clean.patch
	[[ ${CHOST} == *-freebsd* ]] && cd "${S}" && epatch "${FILESDIR}"/${P}-fbsdhints.patch
	cd "${S}"; epatch "${FILESDIR}"/${P}-cplusplus.patch
	has_version '>=sys-devel/gcc-4.2' && epatch "${FILESDIR}"/${P}-gcc42-command-line.patch

	# patch to fix bug #198196
	# UTF/Regular expressions boundary error (CVE-2007-5116)
	epatch "${FILESDIR}"/${P}-utf8-boundary.patch

	# patch to fix bug #219203
	epatch "${FILESDIR}"/${P}-CVE-2008-1927.patch

	# Respect CFLAGS even for linking when done with compiler
	epatch "${FILESDIR}"/${P}-ccld-cflags.patch

	# Respect LDFLAGS
	sed -e 's/$(SHRPLDFLAGS)/& $(LDFLAGS)/' -i Makefile.SH
}

myconf() {
	myconf=( "${myconf[@]}" "$@" )
}

src_compile() {
	declare -a myconf

	# Perl has problems compiling with -Os in your flags
	# some arches and -O do not mix :)
	use ppc && replace-flags -O? -O1
	# Perl has problems compiling with -Os in your flags with glibc
	use elibc_uclibc || replace-flags "-Os" "-O2"
	( gcc-specs-ssp && use ia64 ) && append-flags -fno-stack-protector
	# This flag makes compiling crash in interesting ways
	filter-flags "-malign-double"
	# Fixes bug #97645
	use ppc && filter-flags -mpowerpc-gpopt
	# Fixes bug #143895 on gcc-4.1.1
	filter-flags "-fsched2-use-superblocks"

	export LC_ALL="C"

	case ${CHOST} in
		*-freebsd*) osname="freebsd" ;;
		*-dragonfly*) osname="dragonfly" ;;
		*-netbsd*) osname="netbsd" ;;
		*-openbsd*) osname="openbsd" ;;
		*-darwin*) osname="darwin" ;;

		*) osname="linux" ;;
	esac

	if use ithreads
	then
		einfo "using ithreads"
		mythreading="-multi"
		myconf -Dusethreads
		myarch=${CHOST}
		myarch="${myarch%%-*}-${osname}-thread"
	else
		myarch=${CHOST}
		myarch="${myarch%%-*}-${osname}"
	fi

	local inclist=$(for v in $PERL_OLDVERSEN; do echo -n "$v $v/$myarch$mythreading "; done)

	# allow either gdbm to provide ndbm (in <gdbm/ndbm.h>) or db1

	myndbm='U'
	mygdbm='U'
	mydb='U'

	if use gdbm
	then
		mygdbm='D'
		myndbm='D'
	fi
	if use berkdb
	then
		mydb='D'
		has_version '=sys-libs/db-1*' && myndbm='D'
	fi

	myconf "-${myndbm}i_ndbm" "-${mygdbm}i_gdbm" "-${mydb}i_db"

	if use mips
	then
		# this is needed because gcc 3.3-compiled kernels will hang
		# the machine trying to run this test - check with `Kumba
		# <rac@gentoo.org> 2003.06.26
		myconf -Dd_u32align
	fi

	if use debug
	then
		CFLAGS="${CFLAGS} -g"
		myconf -DDEBUGGING
	fi

	if use sparc
	then
		myconf -Ud_longdbl
	fi

	if use alpha && "$(tc-getCC)" == "ccc"
	then
		ewarn "Perl will not be built with berkdb support, use gcc if you needed it..."
		myconf -Ui_db -Ui_ndbm
	fi

	rm -f config.sh Policy.sh

	[[ -n "${ABI}" ]] && myconf "-Dusrinc=$(get_ml_incdir)"

	[[ ${ELIBC} == "FreeBSD" ]] && myconf "-Dlibc=/usr/$(get_libdir)/libc.a"

	if [[ $(get_libdir) != "lib" ]] ; then
		myconf "-Dlibpth=/usr/local/$(get_libdir) /$(get_libdir) /usr/$(get_libdir)"
	fi

	sh Configure -des \
		-Darchname="${myarch}" \
		-Dcccdlflags="-fPIC" \
		-Dccdlflags="-rdynamic" \
		-Dcc="$(tc-getCC)" \
		-Dprefix="/usr" \
		-Dvendorprefix="/usr" \
		-Dsiteprefix="/usr" \
		-Dlocincpth=" " \
		-Doptimize="${CFLAGS}" \
		-Duselargefiles \
		-Duseshrplib \
		-Dman3ext="3pm" \
		-Dlibperl="${LIBPERL}" \
		-Dd_dosuid \
		-Dd_semctl_semun \
		-Dcf_by="Gentoo" \
		-Ud_csh \
		"${myconf[@]}" || die "Unable to configure"

	emake -j1 -f Makefile depend || die "Couldn't make libperl$(get_libname) depends"
	emake -j1 -f Makefile LDFLAGS="${LDFLAGS}" LIBPERL=${LIBPERL} ${LIBPERL} || die "Unable to make libperl$(get_libname)"
	mv ${LIBPERL} "${WORKDIR}"
}

src_install() {

	export LC_ALL="C"

	if [ "${PN}" = "libperl" ]
	then
		dolib.so "${WORKDIR}"/${LIBPERL}
		dosym ${LIBPERL} /usr/$(get_libdir)/libperl$(get_libname ${PERLSLOT})
	else
		# Need to do this, else apps do not link to dynamic version of
		# the library ...
		local coredir="/usr/$(get_libdir)/perl5/${PV}/${myarch}${mythreading}/CORE"
		dodir ${coredir}
		dosym ../../../../../$(get_libdir)/${LIBPERL} ${coredir}/${LIBPERL}
		dosym ../../../../../$(get_libdir)/${LIBPERL} ${coredir}/libperl$(get_libname ${PERLSLOT})
		dosym ../../../../../$(get_libdir)/${LIBPERL} ${coredir}/libperl$(get_libname)

		# Fix for "stupid" modules and programs
		dodir /usr/$(get_libdir)/perl5/site_perl/${PV}/${myarch}${mythreading}

		make DESTDIR="${D}" \
			INSTALLMAN1DIR="${D}/usr/share/man/man1" \
			INSTALLMAN3DIR="${D}/usr/share/man/man3" \
			install || die "Unable to make install"

		cp -f utils/h2ph utils/h2ph_patched

		LD_LIBRARY_PATH=. ./perl -Ilib utils/h2ph_patched \
			-a -d "${D}"/usr/$(get_libdir)/perl5/${PV}/${myarch}${mythreading} <<EOF
asm/termios.h
syscall.h
syslimits.h
syslog.h
sys/ioctl.h
sys/socket.h
sys/time.h
wait.h
EOF

		# This is to fix a missing c flag for backwards compat
		for i in `find "${D}"/usr/$(get_libdir)/perl5 -iname "Config.pm"`;do
			sed -e "s:ccflags=':ccflags='-DPERL5 :" \
			    -e "s:cppflags=':cppflags='-DPERL5 :" \
				${i} > ${i}.new &&\
				mv ${i}.new ${i} || die "Sed failed"
		done

		# A poor fix for the miniperl issues
		dosed 's:./miniperl:/usr/bin/perl:' /usr/$(get_libdir)/perl5/${PV}/ExtUtils/xsubpp
		fperms 0444 /usr/$(get_libdir)/perl5/${PV}/ExtUtils/xsubpp
		dosed 's:./miniperl:/usr/bin/perl:' /usr/bin/xsubpp
		fperms 0755 /usr/bin/xsubpp

		./perl installman \
			--man1dir="${D}/usr/share/man/man1" --man1ext='1' \
			--man3dir="${D}/usr/share/man/man3" --man3ext='3'

		# This removes ${D} from Config.pm and .packlist
		for i in `find "${D}" -iname "Config.pm"` `find "${D}" -iname ".packlist"`;do
			einfo "Removing ${D} from ${i}..."
			sed -e "s:${D}::" ${i} > "${i}.new" &&\
				mv "${i}.new" "${i}" || die "Sed failed"
		done
	fi

	dodoc Changes* Artistic Copying README Todo* AUTHORS

	if [ "${PN}" = "perl" ]
	then
		# HTML Documentation
		# We expect errors, warnings, and such with the following.

		dodir /usr/share/doc/${PF}/html
		./perl installhtml \
			--podroot='.' \
			--podpath='lib:ext:pod:vms' \
			--recurse \
			--htmldir="${D}/usr/share/doc/${PF}/html" \
			--libpods='perlfunc:perlguts:perlvar:perlrun:perlop'
	fi
}

pkg_postinst() {

	# Make sure we do not have stale/invalid libperl.so 's ...
	if [ -f "${ROOT}usr/$(get_libdir)/libperl$(get_libname)" -a ! -L "${ROOT}usr/$(get_libdir)/libperl$(get_libname)" ]
	then
		mv -f "${ROOT}usr/$(get_libdir)/libperl$(get_libname)" "${ROOT}usr/$(get_libdir)/libperl$(get_libname).old"
	fi

	# Next bit is to try and setup the /usr/lib/libperl.so symlink
	# properly ...
	local libnumber="`ls -1 "${ROOT}"usr/$(get_libdir)/libperl$(get_libname ?.*) | grep -v '\.old' | wc -l`"
	if [ "${libnumber}" -eq 1 ]
	then
		# Only this version of libperl is installed, so just link libperl.so
		# to the *soname* version of it ...
		ln -snf libperl$(get_libname ${PERLSLOT}) "${ROOT}"/usr/$(get_libdir)/libperl$(get_libname)
	else
		if [ -x "${ROOT}/usr/bin/perl" ]
		then
			# OK, we have more than one version .. first try to figure out
			# if there are already a perl installed, if so, link libperl.so
			# to that *soname* version of libperl.so ...
			local perlversion="`${ROOT}/usr/bin/perl -V:version | cut -d\' -f2 | cut -d. -f1,2`"

			cd "${ROOT}"/usr/$(get_libdir)
			# Link libperl.so to the *soname* versioned lib ...
			ln -snf `echo libperl$(get_libname ?.${perlversion}) | cut -d.  -f1,2,3` libperl$(get_libname)
		else
			local x latest

			# Nope, we are not so lucky ... try to figure out what version
			# is the latest, and keep fingers crossed ...
			for x in `ls -1 "${ROOT}"/usr/$(get_libdir)/libperl$(get_libname ?.*)`
			do
				latest="${x}"
			done

			cd "${ROOT}"/usr/$(get_libdir)
			# Link libperl.so to the *soname* versioned lib ...
			ln -snf `echo ${latest##*/} | cut -d. -f1,2,3` libperl$(get_libname)
		fi
	fi
}
