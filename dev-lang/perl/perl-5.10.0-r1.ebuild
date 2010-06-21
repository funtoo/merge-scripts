# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/perl/perl-5.8.8-r2.ebuild,v 1.29 2007/02/11 14:15:44 grobian Exp $

inherit eutils flag-o-matic toolchain-funcs multilib

# The slot of this binary compat version of libperl.so
PERLSLOT="1"

SHORT_PV="${PV%.*}"
MY_P="perl-${PV/_rc/-RC}"
MY_PV="${PV%_rc*}"
DESCRIPTION="Larry Wall's Practical Extraction and Report Language"
S="${WORKDIR}/${MY_P}"
SRC_URI="mirror://cpan/src/${MY_P}.tar.gz"
HOMEPAGE="http://www.perl.org/"
LIBPERL="libperl$(get_libname ${PERLSLOT}.${SHORT_PV})"

LICENSE="|| ( Artistic GPL-2 )"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc sparc-fbsd x86 x86-fbsd"
IUSE="berkdb debug doc gdbm ithreads perlsuid" 
PERL_OLDVERSEN=""

DEPEND="berkdb? ( sys-libs/db )
	gdbm? ( >=sys-libs/gdbm-1.8.3 )
	>=sys-devel/libperl-${PV}
	elibc_FreeBSD? ( sys-freebsd/freebsd-mk-defs )
	!<perl-core/File-Spec-0.87
	!<perl-core/Test-Simple-0.47-r1"

RDEPEND="~sys-devel/libperl-${PV}
	berkdb? ( sys-libs/db )
	gdbm? ( >=sys-libs/gdbm-1.8.3 )"

PDEPEND=">=app-admin/perl-cleaner-1.03
			>=perl-core/PodParser-1.35
			>=perl-core/Test-Harness-2.64
			>=perl-core/Module-Build-0.28.08
			>=perl-core/Archive-Tar-1.38
			>=perl-core/Digest-SHA-5.45"

pkg_setup() {
	# I think this should rather be displayed if you *have* 'ithreads'
	# in USE if it could break things ...
	if use ithreads ; then
		ewarn "PLEASE NOTE: You are compiling ${MY_P} with"
		ewarn "interpreter-level threading enabled."
		ewarn "Threading is not supported by all applications "
		ewarn "that compile against perl. You use threading at "
		ewarn "your own discretion. "
		epause 5
	fi

	if [[ ! -f "${ROOT}/usr/$(get_libdir)/${LIBPERL}" ]] ; then
		# Make sure we have libperl installed ...
		eerror "Cannot find ${ROOT}/usr/$(get_libdir)/${LIBPERL}!  Make sure that you"
		eerror "have sys-libs/libperl installed properly ..."
		die "Cannot find ${ROOT}/usr/$(get_libdir)/${LIBPERL}!"
	fi
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	EPATCH_SOURCE="${FILESDIR}/${PV}" \
	EPATCH_FORCE="yes" \
	EPATCH_SUFFIX="patch" \
	epatch
}

myconf() {
	# the myconf array is declared in src_configure
	myconf=( "${myconf[@]}" "$@" )
}

src_configure() {
	declare -a myconf

	# some arches and -O do not mix :)
	use arm && replace-flags -O? -O1
	use ppc && replace-flags -O? -O1
	use ia64 && replace-flags -O? -O1
	# Perl has problems compiling with -Os in your flags with glibc
	use elibc_uclibc || replace-flags "-Os" "-O2"
	# This flag makes compiling crash in interesting ways
	filter-flags -malign-double
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

	if use ithreads ; then
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

	if use gdbm ; then
		mygdbm='D'
		myndbm='D'
	fi
	if use berkdb ; then
		mydb='D'
		has_version '=sys-libs/db-1*' && myndbm='D'
	fi

	myconf "-${myndbm}i_ndbm" "-${mygdbm}i_gdbm" "-${mydb}i_db"

	if use mips ; then
		# this is needed because gcc 3.3-compiled kernels will hang
		# the machine trying to run this test - check with `Kumba
		# <rac@gentoo.org> 2003.06.26
		myconf -Dd_u32align
	fi

	if use perlsuid ; then
		myconf -Dd_dosuid
		ewarn "You have enabled Perl's suid compile. Please"
		ewarn "read http://perldoc.com/perl5.8.2/INSTALL.html#suidperl"
		epause 3
	fi

	if use debug ; then
		CFLAGS="${CFLAGS} -g"
		myconf -DDEBUGGING
	fi

	if use sparc ; then
		myconf -Ud_longdbl
	fi

	if use alpha && [[ "$(tc-getCC)" = "ccc" ]] ; then
		ewarn "Perl will not be built with berkdb support, use gcc if you needed it..."
		myconf -Ui_db -Ui_ndbm
	fi

	[[ -n "${ABI}" ]] && myconf "-Dusrinc=$(get_ml_incdir)"

	[[ ${ELIBC} == "FreeBSD" ]] && myconf "-Dlibc=/usr/$(get_libdir)/libc.a"

	if [[ $(get_libdir) != "lib" ]] ; then
		# We need to use " and not ', as the written config.sh use ' ...
		myconf "-Dlibpth=/usr/local/$(get_libdir) /$(get_libdir) /usr/$(get_libdir)"
	fi

		sh Configure -des \
		-Darchname="${myarch}" \
		-Dcccdlflags='-fPIC' \
		-Dccdlflags='-rdynamic' \
		-Dcc="gcc" \
		-Dprefix='/usr' \
		-Dvendorprefix='/usr' \
		-Dsiteprefix='/usr' \
		-Dlocincpth=' ' \
		-Doptimize="${CFLAGS}" \
		-Duselargefiles \
		-Dd_semctl_semun \
		-Dscriptdir=/usr/bin \
		-Dman1dir=/usr/share/man/man1 \
		-Dman3dir=/usr/share/man/man3 \
		-Dinstallman1dir=/usr/share/man/man1 \
		-Dinstallman3dir=/usr/share/man/man3 \
		-Dman1ext='1' \
		-Dman3ext='3pm' \
		-Dinc_version_list="$inclist" \
		-Dinc_version_list="$inclist" \
		-Dlocincpth="/usr/src/linux/include" \
		-Dcf_by='Gentoo' \
		-Ud_csh \
		-Dusenm \
		"${myconf[@]}" || die "Unable to configure"
}

src_compile() {
	# would like to bracket this with a test for the existence of a
	# dotfile, but can't clean it automatically now.

	src_configure

	emake -j1 || die "Unable to make"
}

src_test() {
	use elibc_uclibc && export MAKEOPTS="${MAKEOPTS} -j1"
	emake -i test CCDLFLAGS= || die "test failed"
}

src_install() {
	export LC_ALL="C"

	# Need to do this, else apps do not link to dynamic version of
	# the library ...
	local coredir="/usr/$(get_libdir)/perl5/${MY_PV}/${myarch}${mythreading}/CORE"
	dodir ${coredir}
	dosym ../../../../../$(get_libdir)/${LIBPERL} ${coredir}/${LIBPERL}
	dosym ../../../../../$(get_libdir)/${LIBPERL} ${coredir}/libperl$(get_libname ${PERLSLOT})
	dosym ../../../../../$(get_libdir)/${LIBPERL} ${coredir}/libperl$(get_libname)

	# Fix for "stupid" modules and programs
	dodir /usr/$(get_libdir)/perl5/site_perl/${MY_PV}/${myarch}${mythreading}

	make DESTDIR="${D}" install || die "Unable to make install"

	rm "${D}"/usr/bin/perl
	#TODO: eselect?
	ln -s perl${MY_PV} "${D}"/usr/bin/perl

#	cp -f utils/h2ph utils/h2ph_patched
#	epatch "${FILESDIR}"/${PN}-h2ph-ansi-header.patch
#
#	LD_LIBRARY_PATH=. ./perl -Ilib utils/h2ph_patched \
#		-a -d "${D}"/usr/$(get_libdir)/perl5/${MY_PV}/${myarch}${mythreading} <<EOF
#asm/termios.h
#syscall.h
#syslimits.h
#syslog.h
#sys/ioctl.h
#sys/socket.h
#sys/time.h
#wait.h
#EOF

	# This is to fix a missing c flag for backwards compat
	for i in $(find "${D}"/usr/$(get_libdir)/perl5 -iname "Config.pm" ) ; do
		sed -i \
			-e "s:ccflags=':ccflags='-DPERL5 :" \
			-e "s:cppflags=':cppflags='-DPERL5 :" \
			"${i}" || die "Sed failed"
	done

	# A poor fix for the miniperl issues
	dosed 's:./miniperl:/usr/bin/perl:' /usr/$(get_libdir)/perl5/${MY_PV}/ExtUtils/xsubpp
	fperms 0444 /usr/$(get_libdir)/perl5/${MY_PV}/ExtUtils/xsubpp
	dosed 's:./miniperl:/usr/bin/perl:' /usr/bin/xsubpp
	fperms 0755 /usr/bin/xsubpp

	# This removes ${D} from Config.pm and .packlist
	for i in $(find "${D}" -iname "Config.pm" -o -iname ".packlist" ) ; do
		einfo "Removing ${D} from ${i}..."
		sed -i -e "s:${D}::" "${i}" || die "Sed failed"
	done

	# Note: find out from psm why we would need/want this.
	# ( use berkdb && has_version '=sys-libs/db-1*' ) ||
	#	find "${D}" -name "*NDBM*" | xargs rm -f

	dodoc Changes* Artistic Copying README Todo* AUTHORS

	if use doc ; then
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
	#cd `find "${D}" -name Path.pm | sed -e 's/Path.pm//'`
	# CAN patch in bug 79685
	#epatch "${FILESDIR}"/${P}-CAN-2005-0448-rmtree.patch

	# Remove those items we PDPEND on
	rm -f "${D}"/usr/bin/pod2usage
	rm -f "${D}"/usr/bin/podchecker
	rm -f "${D}"/usr/bin/podselect
	rm -f "${D}"/usr/bin/prove
	rm -f "${D}"/usr/bin/ptardiff
	rm -f "${D}"/usr/bin/ptar
	rm -f "${D}"/usr/bin/config_data
	rm -f "${D}"/usr/bin/shasum
	rm -f "${D}"/usr/share/man/man1/pod2usage*
	rm -f "${D}"/usr/share/man/man1/podchecker*
	rm -f "${D}"/usr/share/man/man1/podselect*
	rm -f "${D}"/usr/share/man/man1/prove*
	rm -f "${D}"/usr/share/man/man1/ptardiff*
	rm -f "${D}"/usr/share/man/man1/ptar*
	rm -f "${D}"/usr/share/man/man1/config_data*
	rm -f "${D}"/usr/share/man/man1/shasum*

#	# TODO: Ugly. renaming the files for SLOTting
#	cd "${D}"/usr/bin
#	for bin in "a2p c2ph config_data corelist cpan cpan2dist cpanp cpanp-run-perl dprofpp enc2xs find2perl h2ph h2xs instmodsh libnetcfg perlbug perldoc perlivp piconv pl2pm pod2html pod2latex pod2man pod2text pod2usage podchecker podselect prove psed pstruct ptar ptardiff s2p shasum splain xsubpp"; do
#		mv $bin ${bin}.${MY_PV}
#	done
}

src_remove_extra_files() {
	local prefix="./usr" # ./ is important
	local bindir="${prefix}/bin"
	local perlroot="${prefix}/$(get_libdir)/perl5" # perl installs per-arch dirs
	local prV="${perlroot}/${MY_PV}"
	# myarch and mythreading are defined inside src_configure()
	local prVA="${prV}/${myarch}${mythreading}"

	# I made this list from the Mandr*, Debian and ex-Connectiva perl-base list
	# Then, I added several files to get GNU autotools running
	# FIXME: should this be in a separated file to be sourced?
	local MINIMAL_PERL_INSTALL="
	${bindir}/h2ph
	${bindir}/perl
	${bindir}/perl${MY_PV}
	${bindir}/pod2man
	${prV}/attributes.pm
	${prV}/AutoLoader.pm
	${prV}/autouse.pm
	${prV}/base.pm
	${prV}/bigint.pm
	${prV}/bignum.pm
	${prV}/bigrat.pm
	${prV}/blib.pm
	${prV}/bytes_heavy.pl
	${prV}/bytes.pm
	${prV}/Carp/Heavy.pm
	${prV}/Carp.pm
	${prV}/charnames.pm
	${prV}/Class/Struct.pm
	${prV}/constant.pm
	${prV}/diagnostics.pm
	${prV}/DirHandle.pm
	${prV}/Exporter/Heavy.pm
	${prV}/Exporter.pm
	${prV}/ExtUtils/Command.pm
	${prV}/ExtUtils/Constant.pm
	${prV}/ExtUtils/Embed.pm
	${prV}/ExtUtils/Installed.pm
	${prV}/ExtUtils/Install.pm
	${prV}/ExtUtils/Liblist.pm
	${prV}/ExtUtils/MakeMaker.pm
	${prV}/ExtUtils/Manifest.pm
	${prV}/ExtUtils/Mkbootstrap.pm
	${prV}/ExtUtils/Mksymlists.pm
	${prV}/ExtUtils/MM_Any.pm
	${prV}/ExtUtils/MM_MacOS.pm
	${prV}/ExtUtils/MM.pm
	${prV}/ExtUtils/MM_Unix.pm
	${prV}/ExtUtils/MY.pm
	${prV}/ExtUtils/Packlist.pm
	${prV}/ExtUtils/testlib.pm
	${prV}/ExtUtils/Miniperl.pm
	${prV}/ExtUtils/Command/MM.pm
	${prV}/ExtUtils/Constant/Base.pm
	${prV}/ExtUtils/Constant/Utils.pm
	${prV}/ExtUtils/Constant/XS.pm
	${prV}/ExtUtils/Liblist/Kid.pm
	${prV}/ExtUtils/MakeMaker/bytes.pm
	${prV}/ExtUtils/MakeMaker/vmsish.pm
	${prV}/fields.pm
	${prV}/File/Basename.pm
	${prV}/File/Compare.pm
	${prV}/File/Copy.pm
	${prV}/File/Find.pm
	${prV}/FileHandle.pm
	${prV}/File/Path.pm
	${prV}/File/Spec.pm
	${prV}/File/Spec/Unix.pm
	${prV}/File/stat.pm
	${prV}/filetest.pm
	${prVA}/attrs.pm
	${prVA}/auto/attrs
	${prVA}/auto/Cwd/Cwd$(get_libname)
	${prVA}/auto/Data/Dumper/Dumper$(get_libname)
	${prVA}/auto/DynaLoader/dl_findfile.al
	${prVA}/auto/Fcntl/Fcntl$(get_libname)
	${prVA}/auto/File/Glob/Glob$(get_libname)
	${prVA}/auto/IO/IO$(get_libname)
	${prVA}/auto/POSIX/autosplit.ix
	${prVA}/auto/POSIX/fstat.al
	${prVA}/auto/POSIX/load_imports.al
	${prVA}/auto/POSIX/POSIX.bs
	${prVA}/auto/POSIX/POSIX$(get_libname)
	${prVA}/auto/POSIX/stat.al
	${prVA}/auto/POSIX/tmpfile.al
	${prVA}/auto/re/re$(get_libname)
	${prVA}/auto/Socket/Socket$(get_libname)
	${prVA}/auto/Storable/autosplit.ix
	${prVA}/auto/Storable/_retrieve.al
	${prVA}/auto/Storable/retrieve.al
	${prVA}/auto/Storable/Storable$(get_libname)
	${prVA}/auto/Storable/_store.al
	${prVA}/auto/Storable/store.al
	${prVA}/B/Deparse.pm
	${prVA}/B.pm
	${prVA}/Config.pm
	${prVA}/Config_heavy.pl
	${prVA}/CORE/libperl$(get_libname)
	${prVA}/Cwd.pm
	${prVA}/Data/Dumper.pm
	${prVA}/DynaLoader.pm
	${prVA}/encoding.pm
	${prVA}/Errno.pm
	${prVA}/Fcntl.pm
	${prVA}/File/Glob.pm
	${prVA}/_h2ph_pre.ph
	${prVA}/IO/File.pm
	${prVA}/IO/Handle.pm
	${prVA}/IO/Pipe.pm
	${prVA}/IO.pm
	${prVA}/IO/Seekable.pm
	${prVA}/IO/Select.pm
	${prVA}/IO/Socket.pm
	${prVA}/lib.pm
	${prVA}/NDBM_File.pm
	${prVA}/ops.pm
	${prVA}/POSIX.pm
	${prVA}/re.pm
	${prVA}/Socket.pm
	${prVA}/Storable.pm
	${prVA}/threads
	${prVA}/threads.pm
	${prVA}/XSLoader.pm
	${prV}/Getopt/Long.pm
	${prV}/Getopt/Std.pm
	${prV}/if.pm
	${prV}/integer.pm
	${prV}/IO/Socket/INET.pm
	${prV}/IO/Socket/UNIX.pm
	${prV}/IPC/Open2.pm
	${prV}/IPC/Open3.pm
	${prV}/less.pm
	${prV}/List/Util.pm
	${prV}/locale.pm
	${prV}/open.pm
	${prV}/overload.pm
	${prV}/Pod/InputObjects.pm
	${prV}/Pod/Man.pm
	${prV}/Pod/ParseLink.pm
	${prV}/Pod/Parser.pm
	${prV}/Pod/Select.pm
	${prV}/Pod/Text.pm
	${prV}/Pod/Usage.pm
	${prV}/PerlIO.pm
	${prV}/Scalar/Util.pm
	${prV}/SelectSaver.pm
	${prV}/sigtrap.pm
	${prV}/sort.pm
	${prV}/stat.pl
	${prV}/strict.pm
	${prV}/subs.pm
	${prV}/Symbol.pm
	${prV}/Text/ParseWords.pm
	${prV}/Text/Tabs.pm
	${prV}/Text/Wrap.pm
	${prV}/Time/Local.pm
	${prV}/unicore/Canonical.pl
	${prV}/unicore/Exact.pl
	${prV}/unicore/lib/gc_sc/Digit.pl
	${prV}/unicore/lib/gc_sc/Word.pl
	${prV}/unicore/PVA.pl
	${prV}/unicore/To/Fold.pl
	${prV}/unicore/To/Lower.pl
	${prV}/unicore/To/Upper.pl
	${prV}/utf8_heavy.pl
	${prV}/utf8.pm
	${prV}/vars.pm
	${prV}/vmsish.pm
	${prV}/warnings
	${prV}/warnings.pm
	${prV}/warnings/register.pm"

	if use perlsuid ; then
		MINIMAL_PERL_INSTALL="${MINIMAL_PERL_INSTALL}
		${bindir}/suidperl
		${bindir}/sperl${MY_PV}"
	fi

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

pkg_postinst() {
	INC=$(perl -e 'for $line (@INC) { next if $line eq "."; next if $line =~ m/'${MY_PV}'|etc|local|perl$/; print "$line\n" }')
	if [[ "${ROOT}" = "/" ]] ; then
		ebegin "Removing old .ph files"
		for DIR in ${INC}; do
			if [[ -d "${ROOT}/${DIR}" ]]; then
				for file in $(find "${ROOT}/${DIR}" -name "*.ph" -type f); do
					rm "${ROOT}/${file}"
					einfo "<< ${file}"
				done
			fi
		done
		# Silently remove the now empty dirs
		for DIR in ${INC}; do
			if [[ -d "${ROOT}/${DIR}" ]]; then
				find "${ROOT}/${DIR}" -depth -type d -print0 | xargs -0 -r rmdir &> /dev/null
			fi
		done
		ebegin "Generating ConfigLocal.pm (ignore any error)"
		enc2xs -C
		ebegin "Converting C header files to the corresponding Perl format"
		cd /usr/include
		h2ph *
		h2ph -r sys/* arpa/* netinet/* bits/* security/* asm/* gnu/* linux/* gentoo*
		# TODO: vv isn't it done above already                       ^^^^^
		#cd /usr/include/linux
		#h2ph *
	fi

# This has been moved into a function because rumor has it that a future release
# of portage will allow us to check what version was just removed - which means
# we will be able to invoke this only as needed :)
	# Tried doing this via  -z, but $INC is too big...
	if [[ "${INC}x" != "x" ]]; then
		cleaner_msg
		epause 5
	fi
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
