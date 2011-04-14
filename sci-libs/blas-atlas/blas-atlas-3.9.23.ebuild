# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sci-libs/blas-atlas/blas-atlas-3.9.23.ebuild,v 1.3 2010/12/17 08:09:04 jlec Exp $

inherit eutils toolchain-funcs multilib

DESCRIPTION="Automatically Tuned Linear Algebra Software BLAS implementation"
HOMEPAGE="http://math-atlas.sourceforge.net/"
MY_PN=${PN/blas-/}
PATCH_V="3.9.21"
SRC_URI="mirror://sourceforge/math-atlas/${MY_PN}${PV}.tar.bz2
	mirror://gentoo/${MY_PN}-${PATCH_V}-shared-libs.2.patch.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="doc"

RDEPEND="app-admin/eselect-blas
	app-admin/eselect-cblas
	doc? ( app-doc/blas-docs )"
DEPEND="app-admin/eselect-blas
	app-admin/eselect-cblas
	>=sys-devel/libtool-1.5"

S="${WORKDIR}/ATLAS"

pkg_setup() {
	# icc won't compile (as of icc-10.0.026)
	# and will blow out $PORTAGE_TMPDIR
	if [[ $(tc-getCC) = icc* ]]; then
		eerror "icc compiler is not supported with sci-libs/blas-atlas"
		die "blas-atlas won't compile with icc"
	fi

	echo
	ewarn "Please make sure to disable CPU throttling completely"
	ewarn "during the compile of blas-atlas. Otherwise, all atlas"
	ewarn "generated timings will be completely random and the"
	ewarn "performance of the resulting libraries will be degraded"
	ewarn "considerably."
	echo
	ewarn "For users of <=gcc-4.1 only:"
	ewarn "If you experience failing SANITY tests during"
	ewarn "atlas' compile please try passing -mfpmath=387; this"
	ewarn "option might also result in much better performance"
	ewarn "than using then sse instruction set depending on your"
	ewarn "CPU."
	echo
	ewarn "If blas-atlas fails during linking with a message"
	ewarn "'relocation R_X86_64_32 .... recompile with -fPIC.'"
	ewarn "please re-emerge libtool and then try again."
	echo
	epause 5
}

src_unpack() {
	unpack ${A}

	cd "${S}"
	epatch "${DISTDIR}"/${MY_PN}-${PATCH_V}-shared-libs.2.patch.bz2
	epatch "${FILESDIR}"/${MY_PN}-${PV}-ger-fix.patch
	epatch "${FILESDIR}"/${MY_PN}-asm-gentoo.patch

	BLD_DIR="${S}"/gentoo-build
	mkdir "${BLD_DIR}" || die "failed to generate build directory"
	cd "${BLD_DIR}"
	cp "${FILESDIR}"/war . && chmod a+x war || die "failed to install war"

	local archselect=
	if use amd64 || use ppc64; then
		archselect="-b 64"
	elif use alpha; then
		archselect=""
	else
		archselect="-b 32"
	fi

	# Remove -m64 on alpha, since the compiler doesn't support it
	use alpha && sed -i -e 's/-m64//g' "${S}"/CONFIG/src/probe_comp.c

	# unfortunately, atlas-3.9.0 chokes when passed
	# x86_64-pc-linux-gnu-gcc and friends instead of
	# plain gcc. Hence, we'll have to workaround this
	# until it is fixed by upstream
	local c_compiler=$(tc-getCC)
	if [[ "${c_compiler}" == *gcc* ]]; then
		c_compiler="gcc"
	fi

	../configure \
		--cc="${c_compiler}" \
		--cflags="${CFLAGS}" \
		--prefix="${D}/${DESTTREE}" \
		--libdir="${D}/${DESTTREE}"/$(get_libdir)/atlas \
		--incdir="${D}/${DESTTREE}"/include \
		-C ac "${c_compiler}" -F ac "${CFLAGS}" \
		-C if $(tc-getFC) -F if "${FFLAGS:-'-O2'}" \
		-Ss pmake "\$(MAKE) ${MAKEOPTS}" \
		-Si cputhrchk 0 ${archselect} \
		|| die "configure failed"

	# fix LDFLAGS
	sed -e "s|LDFLAGS =.*|LDFLAGS = ${LDFLAGS}|" \
		-i "${BLD_DIR}"/Make.inc
}

src_compile() {
	cd "${BLD_DIR}"

	# atlas does its own parallel builds
	# â and it fails parallel make, bug #294172
	emake -j1 || die "emake failed"

	RPATH="${DESTTREE}"/$(get_libdir)/blas
	emake -j1 \
		LIBDIR=$(get_libdir) \
		RPATH="${RPATH}"/atlas \
		shared || die "failed to build shared libraries"

	# build shared libraries of threaded libraries if applicable
	if [[ -d gentoo/libptcblas.a ]]; then
		emake -j1 \
			LIBDIR=$(get_libdir) \
			RPATH="${RPATH}"/threaded-atlas \
			ptshared || die "failed to build threaded shared libraries"
	fi
}

src_test() {
	# make check does not work because
	# we don't build lapack libs
	for i in F77 C; do
		einfo "Testing ${i} interface"
		cd "${BLD_DIR}"/interfaces/blas/${i}/testing
		make sanity_test || die "emake tests for ${i} failed"
		if [[ -d "${BLD_DIR}"/gentoo/libptf77blas.a ]]; then
			make ptsanity_test || die "emake tests threaded for ${i}failed"
		fi
	done
	echo "Timing ATLAS"
	cd "${BLD_DIR}"
	emake time || die "emake time failed"
}

src_install () {
	dodir "${RPATH}"/atlas
	cd "${BLD_DIR}"/gentoo/libs
	cp -P libatlas* "${D}/${DESTTREE}"/$(get_libdir) \
		|| die "Failed to install libatlas"

	# pkgconfig files
	local extlibs="-lm"
	local threadlibs
	[[ $(tc-getFC) =~ gfortran ]] && extlibs="${extlibs} -lgfortran"
	[[ $(tc-getFC) =~ g77 ]] && extlibs="${extlibs} -lg2c"
	cp "${FILESDIR}"/blas.pc.in blas.pc
	cp "${FILESDIR}"/cblas.pc.in cblas.pc
	sed -i \
		-e "s:@LIBDIR@:$(get_libdir)/blas/atlas:" \
		-e "s:@PV@:${PV}:" \
		-e "s:@EXTLIBS@:${extlibs}:g" \
		-e "s:@THREADLIBS@:${threadlibs}:g" \
		*blas.pc || die "sed *blas.pc failed"

	cp -P *blas* "${D}/${RPATH}"/atlas \
		|| die "Failed to install blas/cblas"

	ESELECT_PROF=atlas
	eselect blas add $(get_libdir) "${FILESDIR}"/eselect.blas.atlas ${ESELECT_PROF}
	eselect cblas add $(get_libdir) "${FILESDIR}"/eselect.cblas.atlas ${ESELECT_PROF}

	if [[ -d "${BLD_DIR}"/gentoo/threaded-libs ]];	then
		dodir "${RPATH}"/threaded-atlas
		cd "${BLD_DIR}"/gentoo/threaded-libs

		# pkgconfig files
		cp "${FILESDIR}"/blas.pc.in blas.pc
		cp "${FILESDIR}"/cblas.pc.in cblas.pc
		threadlibs="-lpthread"
		sed -i \
			-e "s:@LIBDIR@:$(get_libdir)/blas/threaded-atlas:" \
			-e "s:@PV@:${PV}:" \
			-e "s:@EXTLIBS@:${extlibs}:g" \
			-e "s:@THREADLIBS@:${threadlibs}:g" \
			*blas.pc || die "sed *blas.pc failed"

		cp -P * "${D}/${RPATH}"/threaded-atlas \
			|| die "Failed to install threaded atlas"
		ESELECT_PROF=atlas-threads

		eselect blas add $(get_libdir) "${FILESDIR}"/eselect.blas.threaded-atlas ${ESELECT_PROF}
		eselect cblas add $(get_libdir) "${FILESDIR}"/eselect.cblas.threaded-atlas ${ESELECT_PROF}
	fi

	insinto "${DESTTREE}"/include/atlas
	doins \
		"${S}"/include/cblas.h \
		"${S}"/include/atlas_misc.h \
		"${S}"/include/atlas_enum.h \
		"${S}"/include/atlas_aux.h \
		|| die "failed to install headers"

	# These headers contain the architecture-specific
	# optimizations determined by ATLAS. The atlas-lapack build
	# is much shorter if they are available, so save them:
	doins "${BLD_DIR}"/include/*.h \
		|| die "failed to install timing headers"

	# some docs
	cd "${S}"/doc
	dodoc INDEX.txt AtlasCredits.txt ChangeLog || die "dodoc failed"
	# atlas specific doc (blas generic docs installed by blas-docs)
	if use doc; then
		insinto /usr/share/doc/${PF}
		doins atlas*pdf cblasqref.pdf || die "doins docs failed"
	fi
}

pkg_postinst() {
	for p in blas cblas; do
		local current_p=$(eselect ${p} show | cut -d' ' -f2)
		# this snippet works around the eselect bug #189942 and makes
		# sure that users upgrading from a previous blas-atlas
		# version pick up the new pkg-config files
		if [[ ${current_p} == ${ESELECT_PROF} \
			  || ${current_p} == "threaded-atlas" \
			  || -z ${current_p} ]]; then
			local configfile="${ROOT}"/etc/env.d/${p}/$(get_libdir)/config
			[[ -e ${configfile} ]] && rm -f ${configfile}
			eselect ${p} set ${ESELECT_PROF}
			elog "${p} has been eselected to ${ESELECT_PROF}"
		else
			elog "Current eselected ${p} is ${current_p}"
			elog "To use the ${p} ${ESELECT_PROF} implementation, you have to issue (as root):"
			elog "\t eselect ${p} set ${ESELECT_PROF}"
		fi
	done
}
