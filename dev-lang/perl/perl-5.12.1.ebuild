# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/perl/perl-5.12.1.ebuild,v 1.2 2010/07/15 08:02:34 tove Exp $

EAPI=3

inherit eutils alternatives flag-o-matic toolchain-funcs multilib

PATCH_VER=3

PERL_OLDVERSEN="5.12.0"

SHORT_PV="${PV%.*}"
MY_P="perl-${PV/_rc/-RC}"
MY_PV="${PV%_rc*}"

DESCRIPTION="Larry Wall's Practical Extraction and Report Language"

SRC_URI="
	mirror://cpan/src/${MY_P}.tar.bz2
	mirror://cpan/authors/id/J/JE/JESSE/${MY_P}.tar.bz2
	mirror://gentoo/${MY_P}-${PATCH_VER}.tar.bz2
	http://dev.gentoo.org/~tove/files/${MY_P}-${PATCH_VER}.tar.bz2"
#	mirror://cpan/src/${MY_P}.tar.bz2
#	mirror://gentoo/${MY_P}-${PATCH_VER}.tar.bz2
HOMEPAGE="http://www.perl.org/"

LICENSE="|| ( Artistic GPL-1 GPL-2 GPL-3 )"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"
IUSE="berkdb build debug doc gdbm ithreads"

COMMON_DEPEND="berkdb? ( sys-libs/db )
	gdbm? ( >=sys-libs/gdbm-1.8.3 )
	>=sys-devel/libperl-5.10.1
	!!<sys-devel/libperl-5.10.1
	app-arch/bzip2
	sys-libs/zlib"
DEPEND="${COMMON_DEPEND}
	elibc_FreeBSD? ( sys-freebsd/freebsd-mk-defs )"
RDEPEND="${COMMON_DEPEND}"
PDEPEND=">=app-admin/perl-cleaner-2.2"

S="${WORKDIR}/${MY_P}"

dual_scripts() {
	src_remove_dual_scripts perl-core/Archive-Tar        1.54    ptar ptardiff
	src_remove_dual_scripts perl-core/Digest-SHA         5.47    shasum
	src_remove_dual_scripts perl-core/CPAN               1.9456  cpan
	src_remove_dual_scripts perl-core/CPANPLUS           0.90    cpanp cpan2dist cpanp-run-perl
	src_remove_dual_scripts perl-core/Encode             2.39    enc2xs piconv
	src_remove_dual_scripts perl-core/ExtUtils-MakeMaker 6.56    instmodsh
	src_remove_dual_scripts perl-core/Module-Build       0.3603  config_data
	src_remove_dual_scripts perl-core/Module-CoreList    2.32    corelist
	src_remove_dual_scripts perl-core/PodParser          1.37    pod2usage podchecker podselect
	src_remove_dual_scripts perl-core/Test-Harness       3.17    prove
	src_remove_dual_scripts perl-core/podlators          2.3.1   pod2man pod2text
}

pkg_setup() {
	case ${CHOST} in
		*-freebsd*)   osname="freebsd" ;;
		*-dragonfly*) osname="dragonfly" ;;
		*-netbsd*)    osname="netbsd" ;;
		*-openbsd*)   osname="openbsd" ;;
		*-darwin*)    osname="darwin" ;;
		*)            osname="linux" ;;
	esac

	if use ithreads ; then
		mythreading="-multi"
		myarch="${CHOST%%-*}-${osname}-thread"
	else
		myarch="${CHOST%%-*}-${osname}"
	fi
	if use debug ; then
		myarch="${myarch}-debug"
	fi

	LIBPERL="libperl$(get_libname ${MY_PV} )"
	PRIV_LIB="/usr/$(get_libdir)/perl5/${MY_PV}"
	ARCH_LIB="/usr/$(get_libdir)/perl5/${MY_PV}/${myarch}${mythreading}"
	SITE_LIB="/usr/$(get_libdir)/perl5/site_perl/${MY_PV}"
	SITE_ARCH="/usr/$(get_libdir)/perl5/site_perl/${MY_PV}/${myarch}${mythreading}"
	VENDOR_LIB="/usr/$(get_libdir)/perl5/vendor_perl/${MY_PV}"
	VENDOR_ARCH="/usr/$(get_libdir)/perl5/vendor_perl/${MY_PV}/${myarch}${mythreading}"

	if use ithreads ; then
		ewarn "THREADS WARNING:"
		ewarn "PLEASE NOTE: You are compiling ${MY_P} with"
		ewarn "interpreter-level threading enabled."
		ewarn "Threading is not supported by all applications "
		ewarn "that compile against perl. You use threading at "
		ewarn "your own discretion. "
		echo
	fi
	if has_version "<dev-lang/perl-${SHORT_PV}" ; then
		ewarn "UPDATE THE PERL MODULES:"
		ewarn "After updating dev-lang/perl you must reinstall"
		ewarn "the installed perl modules."
		ewarn "Use: perl-cleaner --all"
		echo
	elif has_version dev-lang/perl ; then
		# doesnot work
		#if ! has_version dev-lang/perl[ithreads=,debug=] ; then
		#if ! has_version dev-lang/perl[ithreads=] || ! has_version dev-lang/perl[debug=] ; then
		if (   use ithreads && ! has_version dev-lang/perl[ithreads]   ) || \
		   ( ! use ithreads &&   has_version dev-lang/perl[ithreads]   ) || \
		   (   use debug    && ! has_version dev-lang/perl[debug]      ) || \
		   ( ! use debug    &&   has_version dev-lang/perl[debug]      ) ; then
			ewarn "TOGGLED USE-FLAGS WARNING:"
			ewarn "You changed one of the use-flags ithreads or debug."
			ewarn "You must rebuild all perl-modules installed."
			ewarn "Use: perl-cleaner --modules ; perl-cleaner --force --libperl"
			echo
		fi
	fi
	dual_scripts
}

src_prepare_update_patchlevel_h() {
	[[ -f ${WORKDIR}/perl-patch/series ]] || return 0

	cat "${WORKDIR}/perl-patch/series" | while read patch level ; do
		sed -i -e "s/^\t,NULL$/	,\"$patch\"\n&/" "${S}"/patchlevel.h || die
	done
}

src_prepare() {
	EPATCH_SOURCE="${WORKDIR}/perl-patch" \
	EPATCH_SUFFIX="diff" \
	EPATCH_FORCE="yes" \
	epatch

	src_prepare_update_patchlevel_h

	# pod/perltoc.pod fails
	# lib/ExtUtils/t/Embed.t fails
	ln -s ${LIBPERL} libperl$(get_libname ${SHORT_PV})
	ln -s ${LIBPERL} libperl$(get_libname )
}

myconf() {
	# the myconf array is declared in src_configure
	myconf=( "${myconf[@]}" "$@" )
}

src_configure() {
	declare -a myconf

	export LC_ALL="C"

	# some arches and -O do not mix :)
	use ppc && replace-flags -O? -O1
	# Perl has problems compiling with -Os in your flags with glibc
	use elibc_uclibc || replace-flags "-Os" "-O2"
	# This flag makes compiling crash in interesting ways
	filter-flags "-malign-double"
	# Fixes bug #97645
	use ppc && filter-flags "-mpowerpc-gpopt"
	# Fixes bug #143895 on gcc-4.1.1
	filter-flags "-fsched2-use-superblocks"

	# this is needed because gcc 3.3-compiled kernels will hang
	# the machine trying to run this test - check with `Kumba
	# <rac@gentoo.org> 2003.06.26
	use mips && myconf -Dd_u32align

	use sparc && myconf -Ud_longdbl

	# 266337
	export BUILD_BZIP2=0
	export BZIP2_INCLUDE=/usr/include
	export BZIP2_LIB=/usr/$(get_libdir)
	cat <<-EOF > "${S}/cpan/Compress-Raw-Zlib/config.in"
		BUILD_ZLIB = False
		INCLUDE = /usr/include
		LIB = /usr/$(get_libdir)

		OLD_ZLIB = False
		GZIP_OS_CODE = AUTO_DETECT
	EOF

	# allow either gdbm to provide ndbm (in <gdbm/ndbm.h>) or db1

	myndbm='U'
	mygdbm='U'
	mydb='U'

	if use gdbm ; then
		mygdbm='D'
		myndbm='D'
	fi
	if use berkdb ; then
		mydb='D'
		has_version '=sys-libs/db-1*' && myndbm='D'
	fi

	myconf "-${myndbm}i_ndbm" "-${mygdbm}i_gdbm" "-${mydb}i_db"

	if use alpha && [[ "$(tc-getCC)" = "ccc" ]] ; then
		ewarn "Perl will not be built with berkdb support, use gcc if you needed it..."
		myconf -Ui_db -Ui_ndbm
	fi

	use ithreads && myconf -Dusethreads

	if use debug ; then
		append-cflags "-g"
		myconf -DDEBUGGING
	fi

	if [[ -n ${PERL_OLDVERSEN} ]] ; then
		local inclist=$(for v in ${PERL_OLDVERSEN}; do echo -n "${v} ${v}/${myarch}${mythreading}"; done )
		myconf -Dinc_version_list="$inclist"
	fi
	[[ -n "${ABI}" ]] && myconf "-Dusrinc=$(get_ml_incdir)"

	[[ ${ELIBC} == "FreeBSD" ]] && myconf "-Dlibc=/usr/$(get_libdir)/libc.a"

	if [[ $(get_libdir) != "lib" ]] ; then
		# We need to use " and not ', as the written config.sh use ' ...
		myconf "-Dlibpth=/usr/local/$(get_libdir) /$(get_libdir) /usr/$(get_libdir)"
	fi

	sh Configure \
		-des \
		-Duseshrplib \
		-Darchname="${myarch}" \
		-Dcc="$(tc-getCC)" \
		-Doptimize="${CFLAGS}" \
		-Dprefix='/usr' \
		-Dsiteprefix='/usr' \
		-Dvendorprefix='/usr' \
		-Dprivlib="${PRIV_LIB}" \
		-Darchlib="${ARCH_LIB}" \
		-Dsitelib="${SITE_LIB}" \
		-Dsitearch="${SITE_ARCH}" \
		-Dvendorlib="${VENDOR_LIB}" \
		-Dvendorarch="${VENDOR_ARCH}" \
		-Dman1dir=/usr/share/man/man1 \
		-Dman3dir=/usr/share/man/man3 \
		-Dsiteman1dir=/usr/share/man/man1 \
		-Dsiteman3dir=/usr/share/man/man3 \
		-Dvendorman1dir=/usr/share/man/man1 \
		-Dvendorman3dir=/usr/share/man/man3 \
		-Dman1ext='1' \
		-Dman3ext='3pm' \
		-Dlibperl="${LIBPERL}" \
		-Dlocincpth=' ' \
		-Duselargefiles \
		-Dd_semctl_semun \
		-Dcf_by='Gentoo' \
		-Dmyhostname='localhost' \
		-Dperladmin='root@localhost' \
		-Dinstallusrbinperl='n' \
		-Ud_csh \
		-Uusenm \
		"${myconf[@]}" || die "Unable to configure"
}

src_test() {
	use elibc_uclibc && export MAKEOPTS="${MAKEOPTS} -j1"
	TEST_JOBS=$(echo -j1 ${MAKEOPTS} | sed -r 's/.*(-j[[:space:]]*|--jobs=)([[:digit:]]+).*/\2/' ) \
		make test_harness || die "test failed"
}

src_install() {
	local i
	local coredir="${ARCH_LIB}/CORE"

#	# Fix for "stupid" modules and programs
#	dodir ${SITE_ARCH} ${SITE_LIB}

	local installtarget=install
	if use build ; then
		installtarget=install.perl
	fi
	make DESTDIR="${D}" ${installtarget} || die "Unable to make ${installtarget}"

	rm -f "${D}"/usr/bin/perl
	ln -s perl${MY_PV} "${D}"/usr/bin/perl

	dolib.so "${D}"/${coredir}/${LIBPERL} || die
	dosym ${LIBPERL} /usr/$(get_libdir)/libperl$(get_libname ${SHORT_PV}) || die
	dosym ${LIBPERL} /usr/$(get_libdir)/libperl$(get_libname) || die
	rm -f "${D}"/${coredir}/${LIBPERL}
	dosym ../../../../../$(get_libdir)/${LIBPERL} ${coredir}/${LIBPERL}
	dosym ../../../../../$(get_libdir)/${LIBPERL} ${coredir}/libperl$(get_libname ${SHORT_PV})
	dosym ../../../../../$(get_libdir)/${LIBPERL} ${coredir}/libperl$(get_libname)

	rm -rf "${D}"/usr/share/man/man3 || die "Unable to remove module man pages"

#	# A poor fix for the miniperl issues
#	dosed 's:./miniperl:/usr/bin/perl:' /usr/$(get_libdir)/perl5/${MY_PV}/ExtUtils/xsubpp
#	fperms 0444 /usr/$(get_libdir)/perl5/${MY_PV}/ExtUtils/xsubpp
#	dosed 's:./miniperl:/usr/bin/perl:' /usr/bin/xsubpp
#	fperms 0755 /usr/bin/xsubpp

	# This removes ${D} from Config.pm
	for i in $(find "${D}" -iname "Config.pm" ) ; do
		einfo "Removing ${D} from ${i}..."
		sed -i -e "s:${D}::" "${i}" || die "Sed failed"
	done

	find "${D}" -type f -name .packlist -delete || die

	# Note: find out from psm why we would need/want this.
	# ( use berkdb && has_version '=sys-libs/db-1*' ) ||
	#	find "${D}" -name "*NDBM*" | xargs rm -f

	dodoc Changes* README AUTHORS || die

	if use doc ; then
		# HTML Documentation
		# We expect errors, warnings, and such with the following.

		dodir /usr/share/doc/${PF}/html
		LD_LIBRARY_PATH=. ./perl installhtml \
			--podroot='.' \
			--podpath='lib:ext:pod:vms' \
			--recurse \
			--htmldir="${D}/usr/share/doc/${PF}/html" \
			--libpods='perlfunc:perlguts:perlvar:perlrun:perlop'
	fi

	dual_scripts

	if use build ; then
		src_remove_extra_files
	fi
}

pkg_postinst() {
	dual_scripts

	if [[ "${ROOT}" = "/" ]] ; then
		local INC DIR file
		INC=$(perl -e 'for $line (@INC) { next if $line eq "."; next if $line =~ m/'${MY_PV}'|etc|local|perl$/; print "$line\n" }')
		ebegin "Removing old .ph files"
		for DIR in ${INC} ; do
			if [[ -d "${DIR}" ]] ; then
				for file in $(find "${DIR}" -name "*.ph" -type f ) ; do
					rm -f "${file}"
					einfo "<< ${file}"
				done
			fi
		done
		# Silently remove the now empty dirs
		for DIR in ${INC} ; do
			if [[ -d "${DIR}" ]] ; then
				find "${DIR}" -depth -type d -print0 | xargs -0 -r rmdir &> /dev/null
			fi
		done
		ebegin "Generating ConfigLocal.pm (ignore any error)"
		enc2xs -C
		ebegin "Converting C header files to the corresponding Perl format"
		pushd /usr/include >/dev/null
			h2ph -Q -a -d ${ARCH_LIB} \
				asm/termios.h syscall.h syslimits.h syslog.h sys/ioctl.h \
				sys/socket.h sys/time.h wait.h sysexits.h
		popd >/dev/null

# This has been moved into a function because rumor has it that a future release
# of portage will allow us to check what version was just removed - which means
# we will be able to invoke this only as needed :)
		# Tried doing this via  -z, but $INC is too big...
		if [[ "${INC}x" != "x" ]]; then
			cleaner_msg
		fi
	fi
}

pkg_postrm(){
	dual_scripts
}

cleaner_msg() {
	eerror "You have had multiple versions of perl. It is recommended"
	eerror "that you run perl-cleaner now. perl-cleaner will"
	eerror "assist with this transition. This script is capable"
	eerror "of cleaning out old .ph files, rebuilding modules for "
	eerror "your new version of perl, as well as re-emerging"
	eerror "applications that compiled against your old libperl$(get_libname)"
	eerror
	eerror "PLEASE DO NOT INTERRUPT THE RUNNING OF THIS SCRIPT."
	eerror "Part of the rebuilding of applications compiled against "
	eerror "your old libperl involves temporarily unmerging"
	eerror "them - interruptions could leave you with unmerged"
	eerror "packages before they can be remerged."
	eerror ""
	eerror "If you have run perl-cleaner and a package still gives"
	eerror "you trouble, and re-emerging it fails to correct"
	eerror "the problem, please check http://bugs.gentoo.org/"
	eerror "for more information or to report a bug."
	eerror ""
}

src_remove_dual_scripts() {

	use build && return

	local i pkg ver ff
	pkg="$1"
	ver="$2"
	shift 2
	if has "${EBUILD_PHASE:-none}" "postinst" "postrm" ;then
		for i in "$@" ; do
			ff=`echo ${ROOT}/usr/share/man/man1/${i}-${ver}-${P}.1*`
			ff=${ff##*.1}
			alternatives_auto_makesym "/usr/bin/${i}" "/usr/bin/${i}-[0-9]*"
			alternatives_auto_makesym "/usr/share/man/man1/${i}.1${ff}" "/usr/share/man/man1/${i}-[0-9]*"
		done
	elif has "${EBUILD_PHASE:-none}" "setup" ; then
		for i in "$@" ; do
			if [[ -f ${ROOT}/usr/bin/${i} && ! -h ${ROOT}/usr/bin/${i} ]] ; then
				has_version ${pkg} && ewarn "You must reinstall $pkg !"
				break
			fi
		done
	else
		for i in "$@" ; do
			mv "${D}"/usr/bin/${i}{,-${ver}-${P}} || die
			if [[ -f ${D}/usr/share/man/man1/${i}.1 ]] ; then
				mv "${D}"/usr/share/man/man1/${i}{.1,-${ver}-${P}.1} || die
			else
				echo "/usr/share/man/man1/${i}.1 does not exist!"
			fi
		done
	fi
}

src_remove_extra_files() {
	local prefix="./usr" # ./ is important
	local bindir="${prefix}/bin"
	local libdir="${prefix}/$(get_libdir)"

	# I made this list from the Mandr*, Debian and ex-Connectiva perl-base list
	# Then, I added several files to get GNU autotools running
	# FIXME: should this be in a separated file to be sourced?
	local MINIMAL_PERL_INSTALL="
	${bindir}/h2ph
	${bindir}/perl
	${bindir}/perl${MY_PV}
	${bindir}/pod2man
	${libdir}/${LIBPERL}
	${libdir}/libperl$(get_libname)
	${libdir}/libperl$(get_libname ${SHORT_PV})
	.${PRIV_LIB}/AutoLoader.pm
	.${PRIV_LIB}/autouse.pm
	.${PRIV_LIB}/B/Deparse.pm
	.${PRIV_LIB}/base.pm
	.${PRIV_LIB}/bigint.pm
	.${PRIV_LIB}/bignum.pm
	.${PRIV_LIB}/bigrat.pm
	.${PRIV_LIB}/blib.pm
	.${PRIV_LIB}/bytes_heavy.pl
	.${PRIV_LIB}/bytes.pm
	.${PRIV_LIB}/Carp/Heavy.pm
	.${PRIV_LIB}/Carp.pm
	.${PRIV_LIB}/charnames.pm
	.${PRIV_LIB}/Class/Struct.pm
	.${PRIV_LIB}/constant.pm
	.${PRIV_LIB}/diagnostics.pm
	.${PRIV_LIB}/DirHandle.pm
	.${PRIV_LIB}/Exporter/Heavy.pm
	.${PRIV_LIB}/Exporter.pm
	.${PRIV_LIB}/ExtUtils/Command.pm
	.${PRIV_LIB}/ExtUtils/Constant.pm
	.${PRIV_LIB}/ExtUtils/Embed.pm
	.${PRIV_LIB}/ExtUtils/Installed.pm
	.${PRIV_LIB}/ExtUtils/Install.pm
	.${PRIV_LIB}/ExtUtils/Liblist.pm
	.${PRIV_LIB}/ExtUtils/MakeMaker.pm
	.${PRIV_LIB}/ExtUtils/Manifest.pm
	.${PRIV_LIB}/ExtUtils/Mkbootstrap.pm
	.${PRIV_LIB}/ExtUtils/Mksymlists.pm
	.${PRIV_LIB}/ExtUtils/MM_Any.pm
	.${PRIV_LIB}/ExtUtils/MM_MacOS.pm
	.${PRIV_LIB}/ExtUtils/MM.pm
	.${PRIV_LIB}/ExtUtils/MM_Unix.pm
	.${PRIV_LIB}/ExtUtils/MY.pm
	.${PRIV_LIB}/ExtUtils/Packlist.pm
	.${PRIV_LIB}/ExtUtils/testlib.pm
	.${PRIV_LIB}/ExtUtils/Miniperl.pm
	.${PRIV_LIB}/ExtUtils/Command/MM.pm
	.${PRIV_LIB}/ExtUtils/Constant/Base.pm
	.${PRIV_LIB}/ExtUtils/Constant/Utils.pm
	.${PRIV_LIB}/ExtUtils/Constant/XS.pm
	.${PRIV_LIB}/ExtUtils/Liblist/Kid.pm
	.${PRIV_LIB}/fields.pm
	.${PRIV_LIB}/File/Basename.pm
	.${PRIV_LIB}/File/Compare.pm
	.${PRIV_LIB}/File/Copy.pm
	.${PRIV_LIB}/File/Find.pm
	.${PRIV_LIB}/FileHandle.pm
	.${PRIV_LIB}/File/Path.pm
	.${PRIV_LIB}/File/stat.pm
	.${PRIV_LIB}/filetest.pm
	.${PRIV_LIB}/Getopt/Long.pm
	.${PRIV_LIB}/Getopt/Std.pm
	.${PRIV_LIB}/if.pm
	.${PRIV_LIB}/integer.pm
	.${PRIV_LIB}/IPC/Open2.pm
	.${PRIV_LIB}/IPC/Open3.pm
	.${PRIV_LIB}/less.pm
	.${PRIV_LIB}/locale.pm
	.${PRIV_LIB}/open.pm
	.${PRIV_LIB}/overload.pm
	.${PRIV_LIB}/Pod/InputObjects.pm
	.${PRIV_LIB}/Pod/Man.pm
	.${PRIV_LIB}/Pod/ParseLink.pm
	.${PRIV_LIB}/Pod/Parser.pm
	.${PRIV_LIB}/Pod/Select.pm
	.${PRIV_LIB}/Pod/Text.pm
	.${PRIV_LIB}/Pod/Usage.pm
	.${PRIV_LIB}/PerlIO.pm
	.${PRIV_LIB}/SelectSaver.pm
	.${PRIV_LIB}/sigtrap.pm
	.${PRIV_LIB}/sort.pm
	.${PRIV_LIB}/stat.pl
	.${PRIV_LIB}/strict.pm
	.${PRIV_LIB}/subs.pm
	.${PRIV_LIB}/Symbol.pm
	.${PRIV_LIB}/Text/ParseWords.pm
	.${PRIV_LIB}/Text/Tabs.pm
	.${PRIV_LIB}/Text/Wrap.pm
	.${PRIV_LIB}/Time/Local.pm
	.${PRIV_LIB}/unicore/Canonical.pl
	.${PRIV_LIB}/unicore/Exact.pl
	.${PRIV_LIB}/unicore/lib/gc_sc/Digit.pl
	.${PRIV_LIB}/unicore/lib/gc_sc/Word.pl
	.${PRIV_LIB}/unicore/PVA.pl
	.${PRIV_LIB}/unicore/To/Fold.pl
	.${PRIV_LIB}/unicore/To/Lower.pl
	.${PRIV_LIB}/unicore/To/Upper.pl
	.${PRIV_LIB}/utf8_heavy.pl
	.${PRIV_LIB}/utf8.pm
	.${PRIV_LIB}/vars.pm
	.${PRIV_LIB}/vmsish.pm
	.${PRIV_LIB}/warnings
	.${PRIV_LIB}/warnings.pm
	.${PRIV_LIB}/warnings/register.pm
	.${PRIV_LIB}/XSLoader.pm
	.${ARCH_LIB}/attributes.pm
	.${ARCH_LIB}/auto/Cwd/Cwd$(get_libname)
	.${ARCH_LIB}/auto/Data/Dumper/Dumper$(get_libname)
	.${ARCH_LIB}/auto/DynaLoader/dl_findfile.al
	.${ARCH_LIB}/auto/Fcntl/Fcntl$(get_libname)
	.${ARCH_LIB}/auto/File/Glob/Glob$(get_libname)
	.${ARCH_LIB}/auto/IO/IO$(get_libname)
	.${ARCH_LIB}/auto/POSIX/autosplit.ix
	.${ARCH_LIB}/auto/POSIX/fstat.al
	.${ARCH_LIB}/auto/POSIX/load_imports.al
	.${ARCH_LIB}/auto/POSIX/POSIX$(get_libname)
	.${ARCH_LIB}/auto/POSIX/stat.al
	.${ARCH_LIB}/auto/POSIX/tmpfile.al
	.${ARCH_LIB}/auto/re/re$(get_libname)
	.${ARCH_LIB}/auto/Socket/Socket$(get_libname)
	.${ARCH_LIB}/auto/Storable/autosplit.ix
	.${ARCH_LIB}/auto/Storable/_retrieve.al
	.${ARCH_LIB}/auto/Storable/retrieve.al
	.${ARCH_LIB}/auto/Storable/Storable$(get_libname)
	.${ARCH_LIB}/auto/Storable/_store.al
	.${ARCH_LIB}/auto/Storable/store.al
	.${ARCH_LIB}/B.pm
	.${ARCH_LIB}/Config.pm
	.${ARCH_LIB}/Config_heavy.pl
	.${ARCH_LIB}/CORE/libperl$(get_libname)
	.${ARCH_LIB}/Cwd.pm
	.${ARCH_LIB}/Data/Dumper.pm
	.${ARCH_LIB}/DynaLoader.pm
	.${ARCH_LIB}/encoding.pm
	.${ARCH_LIB}/Errno.pm
	.${ARCH_LIB}/Fcntl.pm
	.${ARCH_LIB}/File/Glob.pm
	.${ARCH_LIB}/File/Spec.pm
	.${ARCH_LIB}/File/Spec/Unix.pm
	.${ARCH_LIB}/_h2ph_pre.ph
	.${ARCH_LIB}/IO/File.pm
	.${ARCH_LIB}/IO/Handle.pm
	.${ARCH_LIB}/IO/Pipe.pm
	.${ARCH_LIB}/IO.pm
	.${ARCH_LIB}/IO/Seekable.pm
	.${ARCH_LIB}/IO/Select.pm
	.${ARCH_LIB}/IO/Socket.pm
	.${ARCH_LIB}/IO/Socket/INET.pm
	.${ARCH_LIB}/IO/Socket/UNIX.pm
	.${ARCH_LIB}/lib.pm
	.${ARCH_LIB}/List/Util.pm
	.${ARCH_LIB}/NDBM_File.pm
	.${ARCH_LIB}/ops.pm
	.${ARCH_LIB}/POSIX.pm
	.${ARCH_LIB}/re.pm
	.${ARCH_LIB}/Scalar/Util.pm
	.${ARCH_LIB}/Socket.pm
	.${ARCH_LIB}/Storable.pm
	.${ARCH_LIB}/threads
	.${ARCH_LIB}/threads.pm"

	pushd "${D}" > /dev/null
	# Remove cruft
	einfo "Removing files that are not in the minimal install"
	echo "${MINIMAL_PERL_INSTALL}"
	for f in $(find . -type f ) ; do
		has "${f}" ${MINIMAL_PERL_INSTALL} || rm -f "${f}"
	done
	# Remove empty directories
	find . -depth -type d -print0 | xargs -0 -r rmdir &> /dev/null
	popd > /dev/null
}
