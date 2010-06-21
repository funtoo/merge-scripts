# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-2.95.3-r9.ebuild,v 1.7 2008/03/20 20:39:50 vapier Exp $

inherit eutils flag-o-matic toolchain-funcs versionator fixheadtails gnuconfig

# The next command strips most flags from CFLAGS/CXXFLAGS.  If you do
# not like it, comment it out, but do not file bugreports if you run into
# problems.
do_filter_flags() {
	strip-flags

	# In general gcc does not like optimization ... we'll add -O2 where safe
	filter-flags -O?

	# Compile problems with these (bug #6641 among others)...
	filter-flags -fno-exceptions -fomit-frame-pointer -ggdb

	# Are we trying to compile with gcc3 ?  CFLAGS and CXXFLAGS needs to be
	# valid for gcc-2.95.3 ...
	if [[ $(tc-arch) == "x86" || $(tc-arch) == "amd64" ]] ; then
		CFLAGS=${CFLAGS//-mtune=/-mcpu=}
		CXXFLAGS=${CXXFLAGS//-mtune=/-mcpu=}
	fi

	replace-cpu-flags k6-{2,3} k6
	replace-cpu-flags athlon{,-{tbird,4,xp,mp}} i686

	replace-cpu-flags pentium-mmx i586
	replace-cpu-flags pentium{2,3,4} i686

	replace-cpu-flags ev6{7,8} ev6

	export CFLAGS CXXFLAGS
}

export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} = ${CHOST} ]] ; then
	if [[ ${CATEGORY/cross-} != ${CATEGORY} ]] ; then
		export CTARGET=${CATEGORY/cross-}
	fi
fi

LOC="/usr"
GCC_BRANCH_VER="$(get_version_component_range 1-2)"
GCC_RELEASE_VER="$(get_version_component_range 1-3)"

LIBPATH="${LOC}/lib/gcc-lib/${CTARGET}/${GCC_RELEASE_VER}"
BINPATH="${LOC}/${CTARGET}/gcc-bin/${GCC_BRANCH_VER}"
DATAPATH="${LOC}/share/gcc-data/${CTARGET}/${GCC_BRANCH_VER}"
# Dont install in /usr/include/g++/, but in gcc internal directory.
# We will handle /usr/include/g++/ with gcc-config ...
STDCXX_INCDIR="${LIBPATH}/include/g++"

PATCH_VER=1.2
DESCRIPTION="Modern C/C++ compiler written by the GNU people"
HOMEPAGE="http://gcc.gnu.org/"
SRC_URI="ftp://gcc.gnu.org/pub/gcc/releases/${P}/${P}.tar.gz
	mirror://gentoo/${P}-patches-${PATCH_VER}.tar.bz2"

LICENSE="GPL-2 LGPL-2.1"
KEYWORDS="x86 ppc sparc alpha"
IUSE="static nls build multislot nocxx fortran"

if use multislot ; then
	SLOT="${CTARGET}-${GCC_CONFIG_VER}"
elif [[ ${CTARGET} != ${CHOST} ]] ; then
	SLOT="${CTARGET}-${GCC_BRANCH_VER}"
else
	SLOT="${GCC_BRANCH_VER}"
fi

RDEPEND=">=sys-devel/gcc-config-1.4
	>=sys-libs/zlib-1.1.4
	>=sys-apps/texinfo-4.2-r4
	!build? ( >=sys-libs/ncurses-5.2-r2 )"
DEPEND="${RDEPEND}
	!build? ( nls? ( sys-devel/gettext ) )"

# Hack used to patch Makefiles to install into the build dir
FAKE_ROOT=""

src_unpack() {
	unpack ${P}.tar.gz
	unpack ${P}-patches-${PATCH_VER}.tar.bz2
	[[ $(tc-arch ${TARGET}) == "alpha" ]] \
		&& rm -f "${EPATCH_SOURCE}"/10_all_new-atexit.patch

	cd "${S}"
	epatch

	# Fixup libtool to correctly generate .la files with portage
	libtoolize --copy --force

	# Fix outdated head/tails format #65668
	ht_fix_file configure gcc/Makefile.in

	# Currently if any path is changed via the configure script, it breaks
	# installing into ${D}.  We should not patch it in src_install() with
	# absolute paths, as some modules then gets rebuild with the wrong
	# paths.  Thus we use $FAKE_ROOT.
	for x in $(find . -name Makefile.in) ; do
		sed -i \
			-e 's:datadir = @datadir@:datadir = $(FAKE_ROOT)@datadir@:' \
			-e 's:bindir = @bindir@:bindir = $(FAKE_ROOT)@bindir@:' \
			-e 's:gxx_include_dir=${includedir}:gxx_include_dir=$(FAKE_ROOT)${includedir}:' \
			${x} || die "could not sed $x"
	done

	gnuconfig_update
}

src_compile() {
	export LINGUAS=""

	# Make sure we have sane CFLAGS
	do_filter_flags

	# Build in a separate build tree
	mkdir -p "${WORKDIR}"/build
	cd "${WORKDIR}"/build

	local gcclangs="c"
	local myconf=""
	if use build ; then
		myconf="--disable-nls"
	else
		myconf=""
		use !nocxx && gcclangs="${gcclangs},c++"
		use fortran && gcclangs="${gcclangs},f77"
		use nls && myconf="${myconf} --enable-nls --without-included-gettext"
	fi
	[[ -n ${CBUILD} ]] && myconf="${myconf} --build=${CBUILD}"
	[[ ${CHOST} == ${CTARGET} ]] \
		&& myconf="${myconf} --enable-shared --enable-threads=posix" \
		|| myconf="${myconf} --disable-shared --disable-threads"
	myconf="--prefix=${LOC}
		--bindir=${BINPATH}
		--datadir=${DATAPATH}
		--mandir=${DATAPATH}/man
		--infodir=${DATAPATH}/info
		--host=${CHOST}
		--target=${CTARGET}
		--with-system-zlib
		--enable-long-long
		--enable-version-specific-runtime-libs
		--with-local-prefix=${LOC}/local
		--enable-languages=${gcclangs}
		${myconf}
		${EXTRA_ECONF}"
	echo ./configure "${myconf}"
	addwrite "/dev/zero"
	${S}/configure ${myconf} || die "configure failed"

	touch ${S}/gcc/c-gperf.h

	if ! use static ; then
		# Fix for our libtool-portage.patch
		S="${WORKDIR}/build" \
		emake bootstrap-lean \
			LIBPATH="${LIBPATH}" STAGE1_CFLAGS="-O" || die "make failed"
		# Above FLAGS optimize and speedup build, thanks
		# to Jeff Garzik <jgarzik@mandrakesoft.com>
	else
		S="${WORKDIR}/build" \
		emake LDFLAGS=-static bootstrap \
			LIBPATH="${LIBPATH}" STAGE1_CFLAGS="-O" || die "make static failed"
	fi
}

src_install() {
	# Do allow symlinks in ${LOC}/lib/gcc-lib/${CHOST}/${PV}/include as
	# this can break the build.
	for x in ${WORKDIR}/build/gcc/include/* ; do
		[[ -L ${x} ]] && rm -f "${x}"
	done

	# Do the 'make install' from the build directory
	cd ${WORKDIR}/build
	S="${WORKDIR}/build" \
	make \
		prefix=${D}${LOC} \
		bindir=${D}${BINPATH} \
		datadir=${D}${DATAPATH} \
		mandir=${D}${DATAPATH}/man \
		infodir=${D}${DATAPATH}/info \
		LIBPATH="${LIBPATH}" \
		FAKE_ROOT="${D}" \
		install || die

	[[ -r ${D}${BINPATH}/gcc ]] || die "gcc not found in ${D}"

	dodir /lib /usr/bin
	dodir /etc/env.d/gcc
	cat << EOF > ${D}/etc/env.d/gcc/${CTARGET}-${GCC_RELEASE_VER}
PATH="${BINPATH}"
ROOTPATH="${BINPATH}"
LDPATH="${LIBPATH}"
MANPATH="${DATAPATH}/man"
INFOPATH="${DATAPATH}/info"
STDCXX_INCDIR="${STDCXX_INCDIR##*/}"
EOF

	# Make sure we dont have stuff lying around that
	# can nuke multiple versions of gcc
	if ! use build ; then
		cd "${D}"${LIBPATH}

		# Tell libtool files where real libraries are
		for LA in ${D}${LOC}/lib/*.la ${D}${LIBPATH}/../*.la ; do
			if [[ -f ${LA} ]] ; then
				sed -i -e "s:/usr/lib:${LIBPATH}:" "${LA}"
				mv "${LA}" "${D}"${LIBPATH}
			fi
		done

		# Move all the libraries to version specific libdir.
		for x in ${D}${LOC}/lib/*.{so,a}* ${D}${LIBPATH}/../*.{so,a}* ; do
			[[ -f ${x} ]] && mv -f "${x}" "${D}"${LIBPATH}
		done

		# These should be symlinks
		cd "${D}"${BINPATH}
		for x in gcc g++ c++ g77 gcj ; do
			# For some reason, g77 gets made instead of ${CTARGET}-g77... this makes it safe
			[[ -f ${x} ]] && mv ${x} ${CTARGET}-${x}

			if [[ ${CHOST} == ${CTARGET} ]] && [[ -f ${CTARGET}-${x} ]] ; then
				[[ ! -f ${x} ]] && mv ${CTARGET}-${x} ${x}
				ln -sf ${x} ${CTARGET}-${x}
			fi
		done
	fi

	# This one comes with binutils
	rm -f ${D}${LOC}/lib/libiberty.a

	cd ${S}
	if use build ; then
		rm -r "${D}"/usr/share/{man,info}
		rm -r "${D}"/${DATAPATH}/{man,info}
	elif ! has nodoc ${FEATURES} ; then
		cd ${S}
		docinto /
		dodoc README* FAQ MAINTAINERS
		docinto html
		dodoc faq.html
		docinto gcc
		cd ${S}/gcc
		dodoc BUGS ChangeLog* FSFChangeLog* LANGUAGES NEWS PROBLEMS README* SERVICE TESTS.FLUNK
		cd ${S}/libchill
		docinto libchill
		dodoc ChangeLog
		cd ${S}/libf2c
		docinto libf2c
		dodoc ChangeLog changes.netlib README TODO
		cd ${S}/libio
		docinto libio
		dodoc ChangeLog NEWS README
		cd dbz
		docinto libio/dbz
		dodoc README
		cd ../stdio
		docinto libio/stdio
		dodoc ChangeLog*
		cd ${S}/libobjc
		docinto libobjc
		dodoc ChangeLog README* THREADS*
		cd ${S}/libstdc++
		docinto libstdc++
		dodoc ChangeLog NEWS
	fi
	has noman ${FEATURES} && rm -r "${D}"/${DATAPATH}/man
	has noinfo ${FEATURES} && rm -r "${D}"/${DATAPATH}/info
}

pkg_postinst() {
	[[ ${ROOT} != "/" ]] && return 0
	gcc-config --use-portage-chost ${CTARGET}-${GCC_RELEASE_VER}
}
