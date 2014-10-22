# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit multilib eutils pax-utils

# Ebuild notes:
#
# This is a simplified Funtoo gcc ebuild. It has been designed to have a reduced dependency
# footprint, so that libgmp, mpfr and mpc are built as part of the gcc build process and
# are not external dependencies. This makes upgrading these dependencies easier and
# improves upgradability of Funtoo Linux systems, and solves various thorny build issues.
#
# Also, this gcc ebuild no longer uses toolchain.eclass which improves the maintainability
# of the ebuild itself as it is less complex.
#
# -- Daniel Robbins, Apr 19, 2013.
#
# Other important notes on this ebuild:
#
# x86/amd64 architecture support only (for now).
# mudflap is enabled by default.
# lto is disabled by default.
# test is not currently supported.
# objc-gc is enabled by default when objc is enabled.
# gcj is not currently supported by this ebuild.
# graphite is not currently supported by this ebuild.
# multislot is a good USE flag to set when testing this ebuild;
#  (It allows this gcc to co-exist along identical x.y versions.)
# hardened is now supported, but we have deprecated the nopie and
#  nossp USE flags from gentoo.

# Note: multi-stage bootstrapping is currently not being performed.

RESTRICT="strip"
FEATURES=${FEATURES/multilib-strict/}

IUSE="go +fortran objc objc++ openmp" # languages
IUSE="$IUSE cxx multislot nls vanilla doc multilib altivec libssp hardened" # other stuff

if use multislot; then
	SLOT="${PV}"
else
	SLOT="${PV%.*}"
fi

#Hardened Support:
#
# PIE_VER specifies the version of the PIE patches that will be downloaded and applied.
#
# SPECS_VER and SPECS_GCC_VER specifies the version of the "minispecs" files that will
# be used. Minispecs are compiler definitions that are installed that can be used to 
# select various permutations of the hardened compiler, as well as a non-hardened
# compiler, and are typically selected via Gentoo's gcc-config tool.

PIE_VER="0.5.8r1"
SPECS_VER="0.2.0"
SPECS_GCC_VER="4.4.3"
SPECS_A="gcc-${SPECS_GCC_VER}-specs-${SPECS_VER}.tar.bz2"
PIE_A="gcc-${PV}-piepatches-v${PIE_VER}.tar.bz2"

GMP_VER="5.1.2"
MPFR_VER="3.1.2"
MPC_VER="1.0.1"

GCC_A="gcc-${PV}.tar.bz2"
SRC_URI="mirror://gnu/gcc/gcc-${PV}/${GCC_A}"
SRC_URI="$SRC_URI http://www.multiprecision.org/mpc/download/mpc-${MPC_VER}.tar.gz"
SRC_URI="$SRC_URI http://www.mpfr.org/mpfr-${MPFR_VER}/mpfr-${MPFR_VER}.tar.xz"
SRC_URI="$SRC_URI mirror://gnu/gmp/gmp-${GMP_VER}.tar.xz"

#Hardened Support:
SRC_URI="$SRC_URI hardened? ( mirror://gentoo/${SPECS_A} mirror://gentoo/${PIE_A} )"

DESCRIPTION="The GNU Compiler Collection"

LICENSE="GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.3+"
KEYWORDS="*"

RDEPEND="sys-libs/zlib nls? ( sys-devel/gettext ) virtual/libiconv"
DEPEND="${RDEPEND} >=sys-devel/bison-1.875 >=sys-devel/flex-2.5.4 elibc_glibc? ( >=sys-libs/glibc-2.8 ) >=sys-devel/binutils-2.18"
PDEPEND=">=sys-devel/gcc-config-1.5 elibc_glibc? ( >=sys-libs/glibc-2.8 )"

pkg_setup() {
	unset GCC_SPECS # we don't want to use the installed compiler's specs to build gcc!
	unset LANGUAGES #265283
	PREFIX=/usr
	CTARGET=$CHOST
	GCC_BRANCH_VER=${SLOT}
	GCC_CONFIG_VER=${PV}
	DATAPATH=${PREFIX}/share/gcc-data/${CTARGET}/${GCC_CONFIG_VER}
	BINPATH=${PREFIX}/${CTARGET}/gcc-bin/${GCC_CONFIG_VER}
	LIBPATH=${PREFIX}/lib/gcc/${CTARGET}/${GCC_CONFIG_VER}
	STDCXX_INCDIR=${LIBPATH}/include/g++-v${GCC_BRANCH_VER}
}

src_unpack() {
	unpack $GCC_A
	( unpack mpc-${MPC_VER}.tar.gz && mv ${WORKDIR}/mpc-${MPC_VER} ${S}/mpc ) || die "mpc setup fail"
	( unpack mpfr-${MPFR_VER}.tar.xz && mv ${WORKDIR}/mpfr-${MPFR_VER} ${S}/mpfr ) || die "mpfr setup fail"
	( unpack gmp-${GMP_VER}.tar.xz && mv ${WORKDIR}/gmp-${GMP_VER} ${S}/gmp ) || die "gmp setup fail"

	if use hardened; then
		unpack $PIE_A || die "pie unpack fail"
		unpack $SPECS_A || die "specs unpack fail"
	fi

	cd $S
	mkdir ${WORKDIR}/objdir
}

src_prepare() {
	( use vanilla && use hardened ) \
		&& die "vanilla and hardened USE flags are incompatible. Disable one of them"

	# For some reason, when upgrading gcc, the gcc Makefile will install stuff
	# like crtbegin.o into a subdirectory based on the name of the currently-installed
	# gcc version, rather than *our* gcc version. Manually fix this:

	sed -i -e "s/^version :=.*/version := ${GCC_CONFIG_VER}/" ${S}/libgcc/Makefile.in || die

	if ! use vanilla; then
		# The following patch allows pie/ssp specs to be changed via environment
		# variable, which is needed for gcc-config to allow switching of compilers:

		[[ ${CHOST} == ${CTARGET} ]] && cat "${FILESDIR}"/gcc-spec-env-r1.patch | patch -p1 || die "patch fail"

		# Prevent libffi from being installed
		sed -i -e 's/\(install.*:\) install-.*recursive/\1/' "${S}"/libffi/Makefile.in || die
		sed -i -e 's/\(install-data-am:\).*/\1/' "${S}"/libffi/include/Makefile.in || die

		# We use --enable-version-specific-libs with ./configure. This
		# option is designed to place all our libraries into a sub-directory
		# rather than /usr/lib*.  However, this option, even through 4.8.0,
		# does not work 100% correctly without a small fix for
		# libgcc_s.so. See: http://gcc.gnu.org/bugzilla/show_bug.cgi?id=32415.
		# So, we apply a small patch to get this working:

		cat "${FILESDIR}"/gcc-4.6.4-fix-libgcc-s-path-with-vsrl.patch | patch -p1 || die "patch fail"

		# gcc bug #53113
		cat "${FILESDIR}"/gcc-libitm-compflags.patch | patch -p1 || die "patch failed"

		# GCC bug: #58800 - Funtoo bug: FL-1399
		cat "${FILESDIR}"/gcc-4.8-pr58800.patch | patch -p1 || die "patch failed"

		# Hardened patches
		if use hardened; then
			local gcc_hard_flags="-DEFAULT_RELRO -DEFAULT_BIND_NOW -DEFAULT_PIE_SSP"

			EPATCH_MULTI_MSG="Applying PIE patches..." \
				epatch "${WORKDIR}"/piepatch/*.patch

			sed -e '/^ALL_CFLAGS/iHARD_CFLAGS = ' \
				-e 's|^ALL_CFLAGS = |ALL_CFLAGS = $(HARD_CFLAGS) |' \
				-i "${S}"/gcc/Makefile.in

			sed -e '/^ALL_CXXFLAGS/iHARD_CFLAGS = ' \
				-e 's|^ALL_CXXFLAGS = |ALL_CXXFLAGS = $(HARD_CFLAGS) |' \
				-i "${S}"/gcc/Makefile.in

			sed -i -e "/^HARD_CFLAGS = /s|=|= ${gcc_hard_flags} |" "${S}"/gcc/Makefile.in || die
		fi
	fi
}

src_configure() {
	# Determine language support:
	local confgcc
	local GCC_LANG="c,c++"
	if use objc; then
		GCC_LANG+=",objc"
		confgcc+=" --enable-objc-gc"
		use objc++ && GCC_LANG+=",obj-c++"
	fi
	use fortran && GCC_LANG+=",fortran" || confgcc+=" --disable-libquadmath"
	use go && GCC_LANG+=",go"
	confgcc+=" $(use_enable openmp libgomp)"
	confgcc+=" --enable-languages=${GCC_LANG} --disable-libgcj"
	confgcc+=" $(use_enable hardened esp)"

	use libssp || export gcc_cv_libc_provides_ssp=yes

	# ARM
	if use arm ; then
		local a arm_arch=${CTARGET%%-*}
		# Remove trailing endian variations first: eb el be bl b l
		for a in e{b,l} {b,l}e b l ; do
			if [[ ${arm_arch} == *${a} ]] ; then
				arm_arch=${arm_arch%${a}}
				break
			fi
		done

		# Convert armv7{a,r,m} to armv7-{a,r,m}
		local arm_arch_without_dash=${arm_arch}
		[[ ${arm_arch} == armv7? ]] && arm_arch=${arm_arch/7/7-}
		# See if this is a valid --with-arch flag
		if (srcdir=${S}/gcc target=${CTARGET} with_arch=${arm_arch};
			. "${srcdir}"/config.gcc) &>/dev/null
		then
			confgcc+=" --with-arch=${arm_arch}"
		fi

		# Enable hardvfp
		tc-is-softfloat="no"
		local CTARGET_TMP=${CTARGET:-${CHOST}}
		if [[ ${CTARGET_TMP//_/-} == *-softfloat-* ]] ; then
			tc-is-softfloat="yes"
		elif [[ ${CTARGET_TMP//_/-} == *-softfp-* ]] ; then
			tc-is-softfloat="softfp"
		fi

		if [[ $(tc-is-softfloat) == "no" ]] && [[ ${CTARGET} == armv[67]* ]]
		then
			# Follow the new arm hardfp distro standard by default
			confgcc+=" --with-float=hard"
			case ${CTARGET} in
				armv6*) confgcc+=" --with-fpu=vfp" ;;
				armv7*) confgcc+=" --with-fpu=vfpv3-d16" ;;
			esac
		fi
	fi

	local branding="Funtoo"
	if use hardened; then
		branding="$branding Hardened ${PVR}, pie-${PIE_VER}"
	else
		branding="$branding ${PVR}"
	fi

	cd ${WORKDIR}/objdir && ../gcc-${PV}/configure \
		$(use_enable libssp) \
		$(use_enable multilib) \
		--enable-version-specific-runtime-libs \
		--enable-libmudflap \
		--prefix=${PREFIX} \
		--bindir=${BINPATH} \
		--includedir=${LIBPATH}/include \
		--datadir=${DATAPATH} \
		--mandir=${DATAPATH}/man \
		--infodir=${DATAPATH}/info \
		--with-gxx-include-dir=${STDCXX_INCDIR} \
		--enable-libstdcxx-time \
		--enable-__cxa_atexit \
		--enable-clocale=gnu \
		--host=$CHOST \
		--build=$CHOST \
		--disable-ppl \
		--disable-cloog \
		--with-system-zlib \
		--enable-obsolete \
		--disable-werror \
		--enable-secureplt \
		--enable-lto \
		--with-bugurl=http://bugs.funtoo.org \
		--with-pkgversion="$branding" \
		--with-mpfr-include=${S}/mpfr/src \
		--with-mpfr-lib=${WORKDIR}/objdir/mpfr/src/.libs \
		$confgcc \
		|| die "configure fail"

	# The --with-mpfr* lines above are used so that gcc-4.6.4 can find mpfr-3.1.2.
	# It can find 2.4.2 with no problem automatically but needs help with newer versions
	# due to mpfr dir structure changes. We look for includes in the source directory,
	# and libraries in the build (objdir) directory.

	if use arm ; then
		# Source : https://sourceware.org/bugzilla/attachment.cgi?id=6807
		# Workaround for a problem introduced with GMP 5.1.0.
		# If configured by gcc with the "none" host & target, it will result in undefined references 
		# to '__gmpn_invert_limb' during linking.
		# Should be fixed by next version of gcc.
		sed -i "s/none-/${arm_arch_without_dash}-/" ${WORKDIR}/objdir/Makefile || die
	fi

}

src_compile() {
	cd $WORKDIR/objdir
	unset ABI

	emake LIBPATH="${LIBPATH}" bootstrap-lean || die "compile fail"
}

create_gcc_env_entry() {
	dodir /etc/env.d/gcc
	local gcc_envd_base="/etc/env.d/gcc/${CTARGET}-${GCC_CONFIG_VER}"
	local gcc_envd_file="${D}${gcc_envd_base}"
	if [ -z $1 ]; then
		gcc_specs_file=""
	else
		gcc_envd_file="$gcc_envd_file-$1"
		gcc_specs_file="${LIBPATH}/$1.specs"
	fi
	cat <<-EOF > ${gcc_envd_file}
	GCC_PATH="${BINPATH}"
	LDPATH="${LIBPATH}:${LIBPATH}/32"
	MANPATH="${DATAPATH}/man"
	INFOPATH="${DATAPATH}/info"
	STDCXX_INCDIR="${STDCXX_INCDIR##*/}"
	GCC_SPECS="${gcc_specs_file}"
	EOF
}

linkify_compiler_binaries() {
	dodir /usr/bin
	cd "${D}"${BINPATH}
	# Ugh: we really need to auto-detect this list.
	#      It's constantly out of date.

	local binary_languages="cpp gcc g++ c++ gcov"

	use go && binary_languages="${binary_languages} gccgo"
	use fortran && binary_languages="${binary_languages} gfortran"

	for x in ${binary_languages} ; do
		[[ -f ${x} ]] && mv ${x} ${CTARGET}-${x}

		if [[ -f ${CTARGET}-${x} ]] ; then
			ln -sf ${CTARGET}-${x} ${x}
			dosym ${BINPATH}/${CTARGET}-${x} /usr/bin/${x}-${GCC_CONFIG_VER}
			# Create version-ed symlinks
			dosym ${BINPATH}/${CTARGET}-${x} /usr/bin/${CTARGET}-${x}-${GCC_CONFIG_VER}
		fi

		if [[ -f ${CTARGET}-${x}-${GCC_CONFIG_VER} ]] ; then
			rm -f ${CTARGET}-${x}-${GCC_CONFIG_VER}
			ln -sf ${CTARGET}-${x} ${CTARGET}-${x}-${GCC_CONFIG_VER}
		fi
	done
}

tasteful_stripping() {
	# Now do the fun stripping stuff
	env RESTRICT="" CHOST=${CHOST} prepstrip "${D}${BINPATH}"
	env RESTRICT="" CHOST=${CTARGET} prepstrip "${D}${LIBPATH}"
	# gcc used to install helper binaries in lib/ but then moved to libexec/
	[[ -d ${D}${PREFIX}/libexec/gcc ]] && \
		env RESTRICT="" CHOST=${CHOST} prepstrip "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}"
}

doc_cleanups() {
	local cxx_mandir=$(find "${WORKDIR}/objdir/${CTARGET}/libstdc++-v3" -name man)
	if [[ -d ${cxx_mandir} ]] ; then
		# clean bogus manpages #113902
		find "${cxx_mandir}" -name '*_build_*' -exec rm {} \;
		cp -r "${cxx_mandir}"/man? "${D}/${DATAPATH}"/man/
	fi
	has noinfo ${FEATURES} \
		&& rm -r "${D}/${DATAPATH}"/info \
		|| prepinfo "${DATAPATH}"
	has noman ${FEATURES} \
		&& rm -r "${D}/${DATAPATH}"/man \
		|| prepman "${DATAPATH}"
}

src_install() {
	S=$WORKDIR/objdir; cd $S

# PRE-MAKE INSTALL SECTION:

	# from toolchain eclass:
	# Do allow symlinks in private gcc include dir as this can break the build
	find gcc/include*/ -type l -delete

	# Remove generated headers, as they can cause things to break
	# (ncurses, openssl, etc).
	while read x; do
		grep -q 'It has been auto-edited by fixincludes from' "${x}" \
			&& echo "Removing auto-generated header: $x" \
			&& rm -f "${x}"
	done < <(find gcc/include*/ -name '*.h')

# MAKE INSTALL SECTION:

	make -j1 DESTDIR="${D}" install || die

# POST MAKE INSTALL SECTION:

	# Basic sanity check
	local EXEEXT
	eval $(grep ^EXEEXT= "${WORKDIR}"/objdir/gcc/config.log)
	[[ -r ${D}${BINPATH}/gcc${EXEEXT} ]] || die "gcc not found in ${D}"

# GENTOO ENV SETUP

	dodir /etc/env.d/gcc
	create_gcc_env_entry

	if use hardened; then
		create_gcc_env_entry hardenednopiessp
		create_gcc_env_entry hardenednopie
		create_gcc_env_entry hardenednossp
		create_gcc_env_entry vanilla
		insinto ${LIBPATH}
		doins "${WORKDIR}"/specs/*.specs
	fi

# CLEANUPS:

	# Punt some tools which are really only useful while building gcc
	find "${D}" -name install-tools -prune -type d -exec rm -rf "{}" \;
	# This one comes with binutils
	find "${D}" -name libiberty.a -delete
	# prune empty dirs left behind
	find "${D}" -depth -type d -delete 2>/dev/null
	# ownership fix:
	chown -R root:0 "${D}"${LIBPATH} 2>/dev/null
	find "${D}/${LIBPATH}" -name libstdc++.la -type f -exec rm "{}" \;
	find "${D}/${LIBPATH}" -name "*.py" -type f -exec rm "{}" \;

	linkify_compiler_binaries
	tasteful_stripping
	doc_cleanups
	exeinto "${DATAPATH}"
	doexe "${FILESDIR}"/c{89,99} || die

	# Don't scan .gox files for executable stacks - false positives
	if use go; then
		export QA_EXECSTACK="usr/lib*/go/*/*.gox"
		export QA_WX_LOAD="usr/lib*/go/*/*.gox"
	fi

	# Disable RANDMMAP so PCH works.
	pax-mark -r "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}/cc1"
	pax-mark -r "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}/cc1plus"
}

pkg_postinst() {

	# Here, we will auto-enable the new compiler if none is currently enabled, or
	# if this is an _._.x upgrade to an already-installed compiler.

	# One exception is if multislot is enabled in USE, which allows ie. 4.6.9
	# and 4.6.10 to exist alongside one another. In this case, the user must
	# enable this compiler manually.

	local do_config="yes"
	curr_gcc_config=$(env -i ROOT="${ROOT}" gcc-config -c ${CTARGET} 2>/dev/null)
	if [ -n "$curr_gcc_config" ]; then
		CURR_GCC_CONFIG_VER=$(gcc-config -S ${curr_gcc_config} | awk '{print $2}')
		if [ "${CURR_GCC_CONFIG_VER%%.*}" != "${GCC_CONFIG_VER%%.*}" ]; then
			# major versions don't match, don't run gcc-config
			do_config="no"
		fi
		use multislot && do_config="no"
	fi
	if [ "$do_config" == "yes" ]; then
		gcc-config ${CTARGET}-${GCC_CONFIG_VER}
	else
		einfo "This does not appear to be a regular upgrade of gcc, so"
		einfo "gcc ${GCC_CONFIG_VER} will not be automatically enabled as the"
		einfo "default system compiler."
		echo
		einfo "If you would like to make ${GCC_CONFIG_VER} the default system"
		einfo "compiler, then perform the following steps as root:"
		echo
		einfo "gcc-config ${CTARGET}-${GCC_CONFIG_VER}"
		einfo "source /etc/profile"
		echo
	fi
}
