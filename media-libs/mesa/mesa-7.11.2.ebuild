# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/mesa/mesa-7.11.2.ebuild,v 1.14 2012/12/08 17:41:30 ago Exp $

EAPI=3

EGIT_REPO_URI="git://anongit.freedesktop.org/mesa/mesa"

if [[ ${PV} = 9999* ]]; then
	GIT_ECLASS="git-2"
	EXPERIMENTAL="true"
fi

inherit base autotools multilib flag-o-matic python toolchain-funcs ${GIT_ECLASS}

OPENGL_DIR="xorg-x11"

MY_PN="${PN/m/M}"
MY_P="${MY_PN}-${PV/_/-}"
MY_SRC_P="${MY_PN}Lib-${PV/_/-}"

FOLDER="${PV/_rc*/}"

DESCRIPTION="OpenGL-like graphic library for Linux"
HOMEPAGE="http://mesa3d.sourceforge.net/"

SRC_PATCHES="mirror://gentoo/${P}-gentoo-patches-01.tar.bz2"
if [[ $PV = 9999* ]]; then
	SRC_URI="${SRC_PATCHES}"
else
	SRC_URI="ftp://ftp.freedesktop.org/pub/mesa/${FOLDER}/${MY_SRC_P}.tar.bz2
		${SRC_PATCHES}"
fi

LICENSE="MIT LGPL-3 SGI-B-2.0"
SLOT="0"
KEYWORDS="alpha amd64 arm ~hppa ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~sparc-solaris ~x64-solaris ~x86-solaris"

INTEL_CARDS="intel"
RADEON_CARDS="radeon"
VIDEO_CARDS="${INTEL_CARDS} ${RADEON_CARDS} mach64 mga nouveau r128 savage sis vmware tdfx via"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS}
	bindist +classic debug +egl +gallium gbm gles +llvm motif +nptl openvg osmesa pic pax_kernel selinux shared-dricore +shared-glapi kernel_FreeBSD"

LIBDRM_DEPSTRING=">=x11-libs/libdrm-2.4.24"
# not a runtime dependency of this package, but dependency of packages which
# depend on this package, bug #342393
EXTERNAL_DEPEND="
	>=x11-proto/dri2proto-2.2
	>=x11-proto/glproto-1.4.11
"
# keep correct libdrm and dri2proto dep
# keep blocks in rdepend for binpkg
RDEPEND="${EXTERNAL_DEPEND}
	!<x11-base/xorg-server-1.7
	!<=x11-proto/xf86driproto-2.0.3
	classic? ( app-admin/eselect-mesa )
	gallium? ( app-admin/eselect-mesa )
	app-admin/eselect-opengl
	dev-libs/expat
	gbm? ( virtual/udev )
	x11-libs/libICE
	>=x11-libs/libX11-1.3.99.901
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXmu
	x11-libs/libXxf86vm
	motif? (
		x11-libs/motif
		!x11-libs/libGLw )
	gallium? (
		llvm? ( >=sys-devel/llvm-2.8 )
	)
	${LIBDRM_DEPSTRING}[video_cards_nouveau?,video_cards_vmware?]
	video_cards_nouveau? ( <x11-libs/libdrm-2.4.34 )
"
for card in ${INTEL_CARDS}; do
	RDEPEND="${RDEPEND}
		video_cards_${card}? ( ${LIBDRM_DEPSTRING}[video_cards_intel] )
	"
done

for card in ${RADEON_CARDS}; do
	RDEPEND="${RDEPEND}
		video_cards_${card}? ( ${LIBDRM_DEPSTRING}[video_cards_radeon] )
	"
done

DEPEND="${RDEPEND}
	=dev-lang/python-2*
	dev-libs/libxml2[python]
	virtual/pkgconfig
	sys-devel/bison
	sys-devel/flex
	x11-misc/makedepend
	x11-proto/inputproto
	>=x11-proto/xextproto-7.0.99.1
	x11-proto/xf86driproto
	x11-proto/xf86vidmodeproto
"

S="${WORKDIR}/${MY_P}"

# It is slow without texrels, if someone wants slow
# mesa without texrels +pic use is worth the shot
QA_EXECSTACK="usr/lib*/opengl/xorg-x11/lib/libGL.so*"
QA_WX_LOAD="usr/lib*/opengl/xorg-x11/lib/libGL.so*"

# Think about: ggi, fbcon, no-X configs

pkg_setup() {
	# gcc 4.2 has buggy ivopts
	if [[ $(gcc-version) = "4.2" ]]; then
		append-flags -fno-ivopts
	fi

	# recommended by upstream
	append-flags -ffast-math
	# workaround toc-issue wrt #386545
	use ppc64 && append-flags -mminimal-toc

	python_set_active_version 2
	python_pkg_setup
}

src_unpack() {
	default
	[[ $PV = 9999* ]] && git-2_src_unpack
}

src_prepare() {
	# apply patches
	if [[ ${PV} != 9999* && -n ${SRC_PATCHES} ]]; then
		EPATCH_FORCE="yes" \
		EPATCH_SOURCE="${WORKDIR}/patches" \
		EPATCH_SUFFIX="patch" \
		epatch
	fi
	# fix for hardened pax_kernel, bug 240956
	[[ ${PV} != 9999* ]] && epatch "${FILESDIR}"/glx_ro_text_segm.patch

	# FreeBSD 6.* doesn't have posix_memalign().
	if [[ ${CHOST} == *-freebsd6.* ]]; then
		sed -i \
			-e "s/-DHAVE_POSIX_MEMALIGN//" \
			configure.ac || die
	fi
	# Solaris needs some recent POSIX stuff in our case
	if [[ ${CHOST} == *-solaris* ]] ; then
		sed -i -e "s/-DSVR4/-D_POSIX_C_SOURCE=200112L/" configure.ac || die
		sed -i -e 's/uint/unsigned int/g' src/egl/drivers/glx/egl_glx.c || die
	fi

	# In order for mesa to complete it's build process we need to use a tool
	# that it compiles. When we cross compile this clearly does not work
	# so we require mesa to be built on the host system first. -solar
	if tc-is-cross-compiler; then
		sed -i -e "s#^GLSL_CL = .*\$#GLSL_CL = glsl_compiler#g" \
			"${S}"/src/mesa/shader/slang/library/Makefile || die
	fi

	base_src_prepare

	eautoreconf
}

src_configure() {
	local myconf

	if use classic; then
	# Configurable DRI drivers
		driver_enable swrast
		driver_enable video_cards_intel i810 i915 i965
		driver_enable video_cards_nouveau nouveau
		driver_enable video_cards_mach64 mach64
		driver_enable video_cards_mga mga
		driver_enable video_cards_r128 r128
		driver_enable video_cards_radeon radeon r200 r300 r600
		driver_enable video_cards_savage savage
		driver_enable video_cards_sis sis
		driver_enable video_cards_tdfx tdfx
		driver_enable video_cards_via unichrome
	fi

	myconf+="
		$(use_enable !bindist texture-float)
		$(use_enable gles gles1)
		$(use_enable gles gles2)
		$(use_enable egl)
	"
	if use egl; then
		use shared-glapi || die "egl needs shared-glapi. Please either enable shared-glapi or disable the egl use flag ."
		myconf+="
			--with-egl-platforms=x11$(use gbm && echo ",drm")
			$(use_enable gallium gallium-egl)
		"
	fi

	if use !gallium && use !classic; then
		ewarn "You enabled neither classic nor gallium USE flags. No hardware"
		ewarn "drivers will be built."
	fi
	if use gallium; then
		myconf+="
			--with-state-trackers=glx,dri$(use egl && echo ",egl")$(use openvg && echo ",vega")
			$(use_enable llvm gallium-llvm)
			$(use_enable openvg)
		"
		gallium_enable swrast
		gallium_enable video_cards_vmware svga
		gallium_enable video_cards_nouveau nouveau
		gallium_enable video_cards_intel i915 i965
		gallium_enable video_cards_radeon r300 r600
	fi

	# x86 hardened pax_kernel needs glx-rts, bug 240956
	if use pax_kernel; then
		myconf+="
			$(use_enable x86 glx-rts)
		"
	fi

	econf \
		--disable-option-checking \
		--with-driver=dri \
		--disable-glut \
		--without-demos \
		--enable-xcb \
		$(use_enable debug) \
		$(use_enable gbm) \
		$(use_enable motif glw) \
		$(use_enable motif) \
		$(use_enable nptl glx-tls) \
		$(use_enable osmesa gl-osmesa) \
		$(use_enable !pic asm) \
		$(use_enable shared-dricore) \
		$(use_enable shared-glapi) \
		--with-dri-drivers=${DRI_DRIVERS} \
		--with-gallium-drivers=${GALLIUM_DRIVERS} \
		${myconf}
}

src_install() {
	base_src_install

	# Save the glsl-compiler for later use
	if ! tc-is-cross-compiler; then
		dobin "${S}"/src/glsl/glsl_compiler || die
	fi
	# Remove redundant headers
	# GLUT thing
	rm -f "${ED}"/usr/include/GL/glut*.h || die "Removing glut include failed."
	# Glew includes
	rm -f "${ED}"/usr/include/GL/{glew,glxew,wglew}.h \
		|| die "Removing glew includes failed."

	# Install config file for eselect mesa
	insinto /usr/share/mesa
	newins "${FILESDIR}/eselect-mesa.conf.7.11" eselect-mesa.conf || die

	# Move libGL and others from /usr/lib to /usr/lib/opengl/blah/lib
	# because user can eselect desired GL provider.
	ebegin "Moving libGL and friends for dynamic switching"
		dodir /usr/$(get_libdir)/opengl/${OPENGL_DIR}/{lib,extensions,include}
		local x
		for x in "${ED}"/usr/$(get_libdir)/libGL.{la,a,so*}; do
			if [ -f ${x} -o -L ${x} ]; then
				mv -f "${x}" "${ED}"/usr/$(get_libdir)/opengl/${OPENGL_DIR}/lib \
					|| die "Failed to move ${x}"
			fi
		done
		for x in "${ED}"/usr/include/GL/{gl.h,glx.h,glext.h,glxext.h}; do
			if [ -f ${x} -o -L ${x} ]; then
				mv -f "${x}" "${ED}"/usr/$(get_libdir)/opengl/${OPENGL_DIR}/include \
					|| die "Failed to move ${x}"
			fi
		done
	eend $?

	if use classic || use gallium; then
			ebegin "Moving DRI/Gallium drivers for dynamic switching"
			local gallium_drivers=( i915_dri.so i965_dri.so r300_dri.so r600_dri.so swrast_dri.so )
			keepdir /usr/$(get_libdir)/dri
			dodir /usr/$(get_libdir)/mesa
			for x in ${gallium_drivers[@]}; do
				if [ -f "${S}/$(get_libdir)/gallium/${x}" ]; then
					mv -f "${ED}/usr/$(get_libdir)/dri/${x}" "${ED}/usr/$(get_libdir)/dri/${x/_dri.so/g_dri.so}" \
						|| die "Failed to move ${x}"
					insinto "/usr/$(get_libdir)/dri/"
					if [ -f "${S}/$(get_libdir)/${x}" ]; then
						insopts -m0755
						doins "${S}/$(get_libdir)/${x}" || die "failed to install ${x}"
					fi
				fi
			done
			for x in "${ED}"/usr/$(get_libdir)/dri/*.so; do
				if [ -f ${x} -o -L ${x} ]; then
					mv -f "${x}" "${x/dri/mesa}" \
						|| die "Failed to move ${x}"
				fi
			done
			pushd "${ED}"/usr/$(get_libdir)/dri || die "pushd failed"
			ln -s ../mesa/*.so . || die "Creating symlink failed"
			# remove symlinks to drivers known to eselect
			for x in ${gallium_drivers[@]}; do
				if [ -f ${x} -o -L ${x} ]; then
					rm "${x}" || die "Failed to remove ${x}"
				fi
			done
			popd
		eend $?
	fi
}

pkg_postinst() {
	# Switch to the xorg implementation.
	echo
	eselect opengl set --use-old ${OPENGL_DIR}
	# Select classic/gallium drivers
	if use classic || use gallium; then
		eselect mesa set --auto
	fi

	# warn about patent encumbered texture-float
	if use !bindist; then
		elog "USE=\"bindist\" was not set. Potentially patent encumbered code was"
		elog "enabled."
	fi
}

# $1 - VIDEO_CARDS flag
# other args - names of DRI drivers to enable
# TODO: avoid code duplication for a more elegant implementation
driver_enable() {
	case $# in
		# for enabling unconditionally
		1)
			DRI_DRIVERS+=",$1"
			;;
		*)
			if use $1; then
				shift
				for i in $@; do
					DRI_DRIVERS+=",${i}"
				done
			fi
			;;
	esac
}

gallium_enable() {
	case $# in
		# for enabling unconditionally
		1)
			GALLIUM_DRIVERS+=",$1"
			;;
		*)
			if use $1; then
				shift
				for i in $@; do
					GALLIUM_DRIVERS+=",${i}"
				done
			fi
			;;
	esac
}
