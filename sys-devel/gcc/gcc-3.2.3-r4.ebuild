# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-3.2.3-r4.ebuild,v 1.28 2008/08/17 04:18:36 mr_bones_ Exp $

inherit eutils flag-o-matic libtool versionator

# Recently there has been a lot of stability problem in Gentoo-land.  Many
# things can be the cause to this, but I believe that it is due to gcc3
# still having issues with optimizations, or with it not filtering bad
# combinations (protecting the user maybe from himself) yet.
#
# This can clearly be seen in large builds like glibc, where too aggressive
# CFLAGS cause the tests to fail miserbly.
#
# Quote from Nick Jones <carpaski@gentoo.org>, who in my opinion
# knows what he is talking about:
#
#   People really shouldn't force code-specific options on... It's a
#   bad idea. The -march options aren't just to look pretty. They enable
#   options that are sensible (and include sse,mmx,3dnow when appropriate).
#
# The next command strips CFLAGS and CXXFLAGS from nearly all flags.  If
# you do not like it, comment it, but do not bugreport if you run into
# problems.
#
# <azarah@gentoo.org> (13 Oct 2002)
do_filter_flags() {
	strip-flags

	# In general gcc does not like optimization, and add -O2 where
	# it is safe.
	filter-flags -O?
}

# Theoretical cross compiler support
[ ! -n "${CCHOST}" ] && export CCHOST="${CHOST}"

LOC="/usr"
#GCC_BRANCH_VER="`echo ${PV} | awk -F. '{ gsub(/_pre.*|_alpha.*/, ""); print $1 "." $2 }'`"
#GCC_RELEASE_VER="`echo ${PV} | awk '{ gsub(/_pre.*|_alpha.*/, ""); print $0 }'`"
GCC_BRANCH_VER="$(get_version_component_range 1-2)"
GCC_RELEASE_VER="$(get_version_component_range 1-3)"

LIBPATH="${LOC}/lib/gcc-lib/${CCHOST}/${GCC_RELEASE_VER}"
BINPATH="${LOC}/${CCHOST}/gcc-bin/${GCC_BRANCH_VER}"
DATAPATH="${LOC}/share/gcc-data/${CCHOST}/${GCC_BRANCH_VER}"
# Don't install in /usr/include/g++-v3/, but in gcc internal directory.
# We will handle /usr/include/g++-v3/ with gcc-config ...
STDCXX_INCDIR="${LIBPATH}/include/g++-v${GCC_BRANCH_VER/\.*/}"

# ProPolice version
PP_VER1="3_2_2"
PP_VER2="3.2.2-10"

# Patch tarball support ...
#PATCH_VER="1.0"
PATCH_VER=""

# Snapshot support ...
#SNAPSHOT="2002-08-12"
SNAPSHOT=""

# Branch update support ...
GCC_RELEASE_VER="${PV}"  # Tarball, etc used ...

#BRANCH_UPDATE="20021208"
BRANCH_UPDATE=""

if [ -z "${SNAPSHOT}" ]
then
	S="${WORKDIR}/${PN}-${GCC_RELEASE_VER}"
	SRC_URI="ftp://gcc.gnu.org/pub/gcc/releases/${P}/${PN}-${GCC_RELEASE_VER}.tar.bz2"

	if [ -n "${PATCH_VER}" ]
	then
		SRC_URI="${SRC_URI}
		         mirror://gentoo/${P}-patches-${PATCH_VER}.tar.bz2"
	fi

	if [ -n "${BRANCH_UPDATE}" ]
	then
		SRC_URI="${SRC_URI}
		         mirror://gentoo/${PN}-${GCC_RELEASE_VER}-branch-update-${BRANCH_UPDATE}.patch.bz2"
	fi
else
	S="${WORKDIR}/gcc-${SNAPSHOT//-}"
	SRC_URI="ftp://sources.redhat.com/pub/gcc/snapshots/${SNAPSHOT}/gcc-${SNAPSHOT//-}.tar.bz2"
fi
SRC_URI="${SRC_URI}
	mirror://gentoo/protector-${PP_VER2}.tar.gz
	http://www.research.ibm.com/trl/projects/security/ssp/gcc${PP_VER1}/protector-${PP_VER2}.tar.gz
	mirror://gentoo/${P}-manpages.tar.bz2
	mirror://gentoo/${P}-tls-update.patch.bz2"

DESCRIPTION="The GNU Compiler Collection.  Includes C/C++ and java compilers"
HOMEPAGE="http://gcc.gnu.org/"

LICENSE="GPL-2 LGPL-2.1"
# this is a glibc-propolice forced bump to a gcc without guard
# when no binary on the system has references to guard@@libgcc
# hppa has no dependency on propolice for gcc - skip this arch
KEYWORDS="x86 ppc sparc mips alpha -hppa ia64 s390"
IUSE="static nls bootstrap java build"

# Ok, this is a hairy one again, but lets assume that we
# are not cross compiling, than we want SLOT to only contain
# $PV, as people upgrading to new gcc layout will not have
# their old gcc unmerged ...
SLOT="${GCC_BRANCH_VER}"

DEPEND=">=sys-libs/glibc-2.3.2-r3
	mips? ( >=sys-devel/binutils-2.13.90.0.16 )
	!mips? ( >=sys-devel/binutils-2.13.90.0.18 )
	>=sys-devel/gcc-config-1.4
	!build? ( >=sys-libs/ncurses-5.2-r2
		nls? ( sys-devel/gettext ) )"

# this glibc has the glibc guard symbols which are needed for the propolice functions to get moved to glibc
# out of the libgcc in this gcc release, however, the propolice patch itself is not defused by this removal
RDEPEND=">=sys-libs/glibc-2.3.2-r3
	>=sys-devel/gcc-config-1.4
	>=sys-libs/zlib-1.1.4
	>=sys-apps/texinfo-4.2-r4
	!build? ( >=sys-libs/ncurses-5.2-r2 )"

PDEPEND="sys-devel/gcc-config"

# Hack used to patch Makefiles to install into the build dir
FAKE_ROOT=""

chk_gcc_version() {
	# This next bit is for updating libtool linker scripts ...
	local OLD_GCC_VERSION="`gcc -dumpversion`"
	local OLD_GCC_CHOST="$(gcc -v 2>&1 | egrep '^Reading specs' |\
	                       sed -e 's:^.*/gcc-lib/\([^/]*\)/[0-9]\+.*$:\1:')"

	if [ "${OLD_GCC_VERSION}" != "${GCC_RELEASE_VER}" ]
	then
		echo "${OLD_GCC_VERSION}" > "${WORKDIR}/.oldgccversion"
	fi

	if [ -n "${OLD_GCC_CHOST}" ]
	then
		if [ "${CHOST}" = "${CCHOST}" -a "${OLD_GCC_CHOST}" != "${CHOST}" ]
		then
			echo "${OLD_GCC_CHOST}" > "${WORKDIR}/.oldgccchost"
		fi
	fi

	# Did we check the version ?
	touch "${WORKDIR}/.chkgccversion"
}

version_patch() {
	[ ! -f "$1" ] && return 1

	sed -e "s:@PV@:${PVR}:g" ${1} > ${T}/${1##*/}
	epatch ${T}/${1##*/}
}

src_unpack() {
	if [ -z "${SNAPSHOT}" ]
	then
		unpack ${PN}-${GCC_RELEASE_VER}.tar.bz2

		if [ -n "${PATCH_VER}" ]
		then
			unpack ${P}-patches-${PATCH_VER}.tar.bz2
		fi
	else
		unpack gcc-${SNAPSHOT//-}.tar.bz2
	fi

	unpack protector-${PP_VER2}.tar.gz

	cd ${S}
	# Fixup libtool to correctly generate .la files with portage
	elibtoolize --portage --shallow

	echo

	# Branch update ...
	if [ -n "${BRANCH_UPDATE}" ]
	then
		epatch ${DISTDIR}/${PN}-${GCC_RELEASE_VER}-branch-update-${BRANCH_UPDATE}.patch.bz2
	fi

	# Do bulk patches included in ${P}-patches-${PATCH_VER}.tar.bz2
	if [ -n "${PATCH_VER}" ]
	then
		epatch ${WORKDIR}/patch
	fi

	# Update to support TLS and __thread
	epatch ${DISTDIR}/${P}-tls-update.patch.bz2

	# Make gcc's version info specific to Gentoo
	version_patch ${FILESDIR}/3.2.3/gcc323-gentoo-branding.patch

	# ProPolice Stack Smashing protection
	# ProPolice does not work on archs where the stack grows upward (HPPA)
	if [ ${ARCH} != "hppa" ]
	then
		epatch ${WORKDIR}/protector.dif
		cp ${WORKDIR}/protector.c ${WORKDIR}/${P}/gcc/ || die "protector.c not found"
		cp ${WORKDIR}/protector.h ${WORKDIR}/${P}/gcc/ || die "protector.h not found"
		version_patch ${FILESDIR}/3.2.3/gcc-323-propolice-version.patch

		epatch ${FILESDIR}/3.2.3/gcc-3.2.3-move-propolice-into-glibc.patch
	fi

	# Patches from Mandrake/Suse ...
	epatch ${FILESDIR}/3.2.1/gcc31-loop-load-final-value.patch
	epatch ${FILESDIR}/3.2.1/gcc32-strip-dotdot.patch
	epatch ${FILESDIR}/3.2.1/gcc32-athlon-alignment.patch
	epatch ${FILESDIR}/3.2.3/gcc32-c++-classfn-member-template.patch
	epatch ${FILESDIR}/3.2.3/gcc32-mklibgcc-serialize-crtfiles.patch

	# GCC bugfixes ...
	epatch ${FILESDIR}/3.2.2/gcc32-pr7768.patch
	epatch ${FILESDIR}/3.2.2/gcc32-pr8213.patch
	epatch ${FILESDIR}/3.2.3/gcc-3.2.3-poisoned-malloc.patch #225743

	# Get gcc to decreases the number of times the collector has to be run
	# by increasing its memory workspace, bug #16548.
	epatch ${FILESDIR}/3.2.2/gcc322-ggc_page-speedup.patch

	# sparc patches from Redhat ...
	use sparc && epatch ${FILESDIR}/3.2.1/gcc32-sparc32-hack.patch

	# Patches from debian-arm
	if use arm
	then
		epatch ${FILESDIR}/3.2.1/gcc32-arm-disable-mathf.patch
		epatch ${FILESDIR}/3.2.1/gcc32-arm-reload1-fix.patch
	fi
	#ppc mergel miscompilation workaround
	if use ppc
	then
		epatch ${FILESDIR}/3.2.3/gcc-3.2.3-mergel-fix.patch
	fi
	if use hppa
	then
		# There exists a bug in the ebuild patched gcc that prevents hppa from
		# getting build because of default_assemble_visibility is not compiled.
		# Alexander Gabert <pappy@nikita.ath.cx> (14 Jul 2003).
		epatch ${FILESDIR}/3.2.3/gcc323-hppa-default_assemble_visibility.patch
	fi

	# Install our pre generated manpages if we do not have perl ...
	if [ ! -x /usr/bin/perl ]
	then
		cd ${S}; unpack ${P}-manpages.tar.bz2
	fi

	# Currently if any path is changed via the configure script, it breaks
	# installing into ${D}.  We should not patch it in src_install() with
	# absolute paths, as some modules then gets rebuild with the wrong
	# paths.  Thus we use $FAKE_ROOT.
	einfo "Fixing Makefiles..."
	cd ${S}
	for x in $(find . -name Makefile.in)
	do
		# Fix --datadir=
		cp ${x} ${x}.orig
		sed -e 's:datadir = @datadir@:datadir = $(FAKE_ROOT)@datadir@:' \
			${x}.orig > ${x}

		# Fix --bindir=
		cp ${x} ${x}.orig
		sed -e 's:bindir = @bindir@:bindir = $(FAKE_ROOT)@bindir@:' \
			${x}.orig > ${x}

		# Fix --includedir=
		cp ${x} ${x}.orig
		sed -e 's:includedir = @includedir@:includedir = $(FAKE_ROOT)@includedir@:' \
			${x}.orig > ${x}

		# Fix --with-gxx-include-dir=
		cp ${x} ${x}.orig
		sed -e 's:gxx_include_dir = @gxx_:gxx_include_dir = $(FAKE_ROOT)@gxx_:' \
			-e 's:glibcppinstalldir = @gxx_:glibcppinstalldir = $(FAKE_ROOT)@gxx_:' \
			${x}.orig > ${x}

		# Where java security stuff should be installed
		cp ${x} ${x}.orig
		sed -e 's:secdir = $(libdir)/security:secdir = $(FAKE_ROOT)$(LIBPATH)/security:' \
			${x}.orig > ${x}

		rm -f ${x}.orig
	done
}

src_compile() {
	local myconf=""
	local gcc_lang=""

	if ! use build
	then
		myconf="${myconf} --enable-shared"
		gcc_lang="c,c++,f77,objc"
	else
		gcc_lang="c"
	fi
	if ! use nls || use build
	then
		myconf="${myconf} --disable-nls"
	else
		myconf="${myconf} --enable-nls --without-included-gettext"
	fi
	if use java && ! use build
	then
		gcc_lang="${gcc_lang},java"
	fi

	do_filter_flags

	# Build in a separate build tree
	mkdir -p ${WORKDIR}/build
	cd ${WORKDIR}/build

	einfo "Configuring GCC..."
	addwrite "/dev/zero"
	${S}/configure --prefix=${LOC} \
		--bindir=${BINPATH} \
		--includedir=${LIBPATH}/include \
		--datadir=${DATAPATH} \
		--mandir=${DATAPATH}/man \
		--infodir=${DATAPATH}/info \
		--enable-shared \
		--host=${CHOST} \
		--target=${CCHOST} \
		--with-system-zlib \
		--enable-languages=${gcc_lang} \
		--enable-threads=posix \
		--enable-long-long \
		--disable-checking \
		--enable-cstdio=stdio \
		--enable-clocale=generic \
		--enable-__cxa_atexit \
		--enable-version-specific-runtime-libs \
		--with-gxx-include-dir=${STDCXX_INCDIR} \
		--with-local-prefix=${LOC}/local \
		${myconf} || die

	touch ${S}/gcc/c-gperf.h

	# Do not make manpages if we do not have perl ...
	if [ ! -x /usr/bin/perl ]
	then
		find ${S} -name '*.[17]' -exec touch {} \; || :
	fi

	einfo "Building GCC..."
	# Only build it static if we are just building the C frontend, else
	# a lot of things break because there are not libstdc++.so ....
	if use static && [ "${gcc_lang}" = "c" ]
	then
		# Fix for our libtool-portage.patch
		S="${WORKDIR}/build" \
		emake LDFLAGS="-static" bootstrap \
			LIBPATH="${LIBPATH}" \
			BOOT_CFLAGS="${CFLAGS}" STAGE1_CFLAGS="-O" || die
		# Above FLAGS optimize and speedup build, thanks
		# to Jeff Garzik <jgarzik@mandrakesoft.com>
	else
		# Fix for our libtool-portage.patch
		S="${WORKDIR}/build" \
		emake bootstrap-lean \
			LIBPATH="${LIBPATH}" \
			BOOT_CFLAGS="${CFLAGS}" STAGE1_CFLAGS="-O" || die
	fi
}

src_install() {
	# Do allow symlinks in ${LOC}/lib/gcc-lib/${CHOST}/${PV}/include as
	# this can break the build.
	for x in cd ${WORKDIR}/build/gcc/include/*
	do
		if [ -L ${x} ]
		then
			rm -f ${x}
		fi
	done
	# Remove generated headers, as they can cause things to break
	# (ncurses, openssl, etc).
	for x in `find ${WORKDIR}/build/gcc/include/ -name '*.h'`
	do
		if grep -q 'It has been auto-edited by fixincludes from' ${x}
		then
			rm -f ${x}
		fi
	done

	einfo "Installing GCC..."
	# Do the 'make install' from the build directory
	cd ${WORKDIR}/build
	S="${WORKDIR}/build" \
	make prefix=${D}${LOC} \
		bindir=${D}${BINPATH} \
		includedir=${D}${LIBPATH}/include \
		datadir=${D}${DATAPATH} \
		mandir=${D}${DATAPATH}/man \
		infodir=${D}${DATAPATH}/info \
		LIBPATH="${LIBPATH}" \
		FAKE_ROOT="${D}" \
		install || die

	[ -r ${D}${BINPATH}/gcc ] || die "gcc not found in ${D}"

	dodir /lib /usr/bin
	dodir /etc/env.d/gcc
	echo "PATH=\"${BINPATH}\"" > ${D}/etc/env.d/gcc/${CCHOST}-${GCC_RELEASE_VER}
	echo "ROOTPATH=\"${BINPATH}\"" >> ${D}/etc/env.d/gcc/${CCHOST}-${GCC_RELEASE_VER}
	echo "LDPATH=\"${LIBPATH}\"" >> ${D}/etc/env.d/gcc/${CCHOST}-${GCC_RELEASE_VER}
	echo "MANPATH=\"${DATAPATH}/man\"" >> ${D}/etc/env.d/gcc/${CCHOST}-${GCC_RELEASE_VER}
	echo "INFOPATH=\"${DATAPATH}/info\"" >> ${D}/etc/env.d/gcc/${CCHOST}-${GCC_RELEASE_VER}
	echo "STDCXX_INCDIR=\"${STDCXX_INCDIR##*/}\"" >> ${D}/etc/env.d/gcc/${CCHOST}-${GCC_RELEASE_VER}
	# Also set CC and CXX
	echo "CC=\"gcc\"" >> ${D}/etc/env.d/gcc/${CCHOST}-${GCC_RELEASE_VER}
	echo "CXX=\"g++\"" >> ${D}/etc/env.d/gcc/${CCHOST}-${GCC_RELEASE_VER}

	# Install wrappers
# Handled by gcc-config now ...
#	exeinto /lib
#	doexe ${FILESDIR}/cpp
#	exeinto /usr/bin
#	doexe ${FILESDIR}/cc

	# Make sure we dont have stuff lying around that
	# can nuke multiple versions of gcc
	if ! use build
	then
		cd ${D}${LIBPATH}

		# Tell libtool files where real libraries are
		for LA in ${D}${LOC}/lib/*.la ${D}${LIBPATH}/../*.la
		do
			if [ -f ${LA} ]
			then
				sed -e "s:/usr/lib:${LIBPATH}:" ${LA} > ${LA}.hacked
				mv ${LA}.hacked ${LA}
				mv ${LA} ${D}${LIBPATH}
			fi
		done

		# Move all the libraries to version specific libdir.
		for x in ${D}${LOC}/lib/*.{so,a}* ${D}${LIBPATH}/../*.{so,a}*
		do
			[ -f ${x} ] && mv -f ${x} ${D}${LIBPATH}
		done

		# Move Java headers to compiler-specific dir
		for x in ${D}${LOC}/include/gc*.h ${D}${LOC}/include/j*.h
		do
			[ -f ${x} ] && mv -f ${x} ${D}${LIBPATH}/include/
		done
		for x in gcj gnu java javax org
		do
			if [ -d ${D}${LOC}/include/${x} ]
			then
				dodir /${LIBPATH}/include/${x}
				mv -f ${D}${LOC}/include/${x}/* ${D}${LIBPATH}/include/${x}/
				rm -rf ${D}${LOC}/include/${x}
			fi
		done

		# Move libgcj.spec to compiler-specific directories
		[ -f ${D}${LOC}/lib/libgcj.spec ] && \
			mv -f ${D}${LOC}/lib/libgcj.spec ${D}${LIBPATH}/libgcj.spec

		# Rename jar because it could clash with Kaffe's jar if this gcc is
		# primary compiler (aka don't have the -<version> extension)
		cd ${D}${LOC}/${CCHOST}/gcc-bin/${GCC_BRANCH_VER}
		[ -f jar ] && mv -f jar gcj-jar

		# Move <cxxabi.h> to compiler-specific directories
		[ -f ${D}${STDCXX_INCDIR}/cxxabi.h ] && \
			mv -f ${D}${STDCXX_INCDIR}/cxxabi.h ${D}${LIBPATH}/include/

		# These should be symlinks
		cd ${D}${BINPATH}
		rm -f ${CCHOST}-{gcc,g++,c++,g77}
		[ -f gcc ] && ln -sf gcc ${CCHOST}-gcc
		[ -f g++ ] && ln -sf g++ ${CCHOST}-g++
		[ -f g++ ] && ln -sf g++ ${CCHOST}-c++
		[ -f g77 ] && ln -sf g77 ${CCHOST}-g77
	fi

	# This one comes with binutils
	if [ -f ${D}${LOC}/lib/libiberty.a ]
	then
		rm -f ${D}${LOC}/lib/libiberty.a
	fi

	cd ${S}
	if ! use build
	then
		cd ${S}
		docinto /${CCHOST}
		dodoc ChangeLog FAQ GNATS MAINTAINERS README
		docinto ${CCHOST}/html
		dohtml *.html
		cd ${S}/boehm-gc
		docinto ${CCHOST}/boehm-gc
		dodoc ChangeLog doc/{README*,barrett_diagram}
		docinto ${CCHOST}/boehm-gc/html
		dohtml doc/*.html
		cd ${S}/gcc
		docinto ${CCHOST}/gcc
		dodoc ChangeLog* FSFChangeLog* LANGUAGES NEWS ONEWS README* SERVICE
		cd ${S}/libf2c
		docinto ${CCHOST}/libf2c
		dodoc ChangeLog README TODO *.netlib
		cd ${S}/libffi
		docinto ${CCHOST}/libffi
		dodoc ChangeLog* README
		cd ${S}/libiberty
		docinto ${CCHOST}/libiberty
		dodoc ChangeLog README
		cd ${S}/libobjc
		docinto ${CCHOST}/libobjc
		dodoc ChangeLog README* THREADS*
		cd ${S}/libstdc++-v3
		docinto ${CCHOST}/libstdc++-v3
		dodoc ChangeLog* README
		docinto ${CCHOST}/libstdc++-v3/html
		dohtml -r -a css,diff,html,txt,xml docs/html/*

		if use java
		then
			cd ${S}/fastjar
			docinto ${CCHOST}/fastjar
			dodoc AUTHORS CHANGES ChangeLog NEWS README
			cd ${S}/libjava
			docinto ${CCHOST}/libjava
			dodoc ChangeLog* HACKING LIBGCJ_LICENSE NEWS README THANKS
		fi

		prepman ${DATAPATH}
		prepinfo ${DATAPATH}
	else
		rm -rf ${D}/usr/share/{man,info}
		rm -rf ${D}${DATAPATH}/{man,info}
	fi

	# Rather install the script, else portage with changing $FILESDIR
	# between binary and source package borks things ....
	insinto /lib/rcscripts/awk
	doins ${FILESDIR}/awk/fixlafiles.awk
	exeinto /sbin
	doexe ${FILESDIR}/fix_libtool_files.sh

	# Fix ncurses b0rking
	find ${D}/ -name '*curses.h' -exec rm -f {} \;
}

pkg_preinst() {
	if [ ! -f "${WORKDIR}/.chkgccversion" ]
	then
		chk_gcc_version
	fi

	# Make again sure that the linker "should" be able to locate
	# libstdc++.so ...
	export LD_LIBRARY_PATH="${LIBPATH}:${LD_LIBRARY_PATH}"
	${ROOT}/sbin/ldconfig
}

pkg_postinst() {
	export LD_LIBRARY_PATH="${LIBPATH}:${LD_LIBRARY_PATH}"

	if [ "${ROOT}" = "/" -a "${CHOST}" = "${CCHOST}" ]
	then
		gcc-config --use-portage-chost ${CCHOST}-${GCC_RELEASE_VER}
	fi

	# Update libtool linker scripts to reference new gcc version ...
	if [ "${ROOT}" = "/" ] && \
	   [ -f "${WORKDIR}/.oldgccversion" -o -f "${WORKDIR}/.oldgccchost" ]
	then
		local OLD_GCC_VERSION=
		local OLD_GCC_CHOST=

		if [ -f "${WORKDIR}/.oldgccversion" ] && \
		   [ -n "$(cat "${WORKDIR}/.oldgccversion")" ]
		then
			OLD_GCC_VERSION="$(cat "${WORKDIR}/.oldgccversion")"
		else
			OLD_GCC_VERSION="${GCC_RELEASE_VER}"
		fi

		if [ -f "${WORKDIR}/.oldgccchost" ] && \
		   [ -n "$(cat "${WORKDIR}/.oldgccchost")" ]
		then
			OLD_GCC_CHOST="--oldarch $(cat "${WORKDIR}/.oldgccchost")"
		fi

		/sbin/fix_libtool_files.sh ${OLD_GCC_VERSION} ${OLD_GCC_CHOST}
	fi

	# Fix ncurses b0rking (if r5 isn't unmerged)
	find ${ROOT}/usr/lib/gcc-lib -name '*curses.h' -exec rm -f {} \;
}
