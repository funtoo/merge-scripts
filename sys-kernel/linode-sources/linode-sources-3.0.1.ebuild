# Distributed under the terms of the GNU General Public License v2

EAPI=2

inherit mount-boot

SLOT=$PVR
CKV=3.0.1
KV_MAJOR=3
KV_MINOR=0
OKV=$CKV
OVZ_KERNEL="linode"
OVZ_REV="1"
OVZ_KV=${OVZ_KERNEL}.${OVZ_REV}
KV_FULL=${PN}-${PVR}
EXTRAVERSION=-${OVZ_KV}
KERNEL_ARCHIVE="linux-${CKV}.tar.bz2"
KERNEL_URI="mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/${KERNEL_ARCHIVE}"
RESTRICT="binchecks strip"

LICENSE="GPL-2"
KEYWORDS="~x86 ~amd64"
IUSE="binary"
DEPEND="binary? ( >=sys-kernel/genkernel-3.4.12.6-r4 )"
DESCRIPTION="Full Linux kernel sources - Linode patchset"
HOMEPAGE="http://www.linode.com"
SRC_URI="${KERNEL_URI}"
S="$WORKDIR/linux-${CKV}"

K_EXTRAEINFO="
This kernel is a build for the Linode hosting service, where you can start
your own images. It is based on 3.0.1 in vanilla version and uses their gentoo
config. Further Modification only by the Funtoo Linux project.
"

src_unpack() {
	unpack ${KERNEL_ARCHIVE}
}

apply() {
	p=$1; shift
	case "${p##*.}" in
		gz)
			ca="gzip -dc"
			;;
		bz2)
			ca="bzip2 -dc"
			;;
		xz)
			ca="xz -dc"
			;;
		*)
			ca="cat"
			;;
	esac
	[ ! -e $p ] && die "patch $p not found"
	echo "Applying patch $p"; $ca $p | patch -s $* || die "patch $p failed"
}

pkg_setup() {
	case $ARCH in
		x86)
			defconfig_src=i686
			;;
		amd64)
			defconfig_src=x86_64
			;;
		*)
			die "unsupported ARCH: $ARCH"
			;;
	esac
	defconfig_src="${FILESDIR}/config-${CKV}-${OVZ_KV}.${defconfig_src}"
	unset ARCH; unset LDFLAGS #will interfere with Makefile if set
}

src_prepare() {
	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${EXTRAVERSION}:" Makefile || die
	sed	-i -e 's:#export\tINSTALL_PATH:export\tINSTALL_PATH:' Makefile || die
	cp $FILESDIR/config-${CKV}-${OVZ_KV}.i686 arch/x86/configs/i386_defconfig || die
	cp $FILESDIR/config-${CKV}-${OVZ_KV}.x86_64 arch/x86/configs/x86_64_defconfig || die
	rm -f .config >/dev/null
	make -s mrproper || die "make mrproper failed"
	make -s include/linux/version.h || die "make include/linux/version.h failed"
}

src_compile() {
	! use binary && return
	install -d ${WORKDIR}/out/{lib,boot}
	install -d ${T}/{cache,twork}
	install -d $WORKDIR/build $WORKDIR/out/lib/firmware
	DEFAULT_KERNEL_SOURCE="${S}" INSTALL_FW_PATH=${WORKDIR}/out/lib/firmware CMD_KERNEL_DIR="${S}" genkernel ${GKARGS} \
		--no-save-config \
		--kernel-config="$defconfig_src" \
		--kernname="${PN/-sources/}" \
		--build-src="$S" \
		--build-dst=${WORKDIR}/build \
		--makeopts="${MAKEOPTS}" \
		--firmware-dst=${WORKDIR}/out/lib/firmware \
		--cachedir="${T}/cache" \
		--tempdir="${T}/twork" \
		--logfile="${WORKDIR}/genkernel.log" \
		--bootdir="${WORKDIR}/out/boot" \
		--lvm \
		--luks \
		--iscsi \
		--module-prefix="${WORKDIR}/out" \
		all || die "genkernel failed"
}

src_install() {
	# copy sources into place:
	dodir /usr/src
	cp -a ${S} ${D}/usr/src/linux-${P} || die
	cd ${D}/usr/src/linux-${P}
	# prepare for real-world use and 3rd-party module building:
	make mrproper || die
	cp $defconfig_src .config || die
	make oldconfig || die
	# if we didn't use genkernel, we're done. The kernel source tree is left in
	# an unconfigured state - you can't compile 3rd-party modules against it yet.
	use binary || return
	make prepare || die
	make scripts || die
	# OK, now the source tree is configured to allow 3rd-party modules to be
	# built against it, since we want that to work since we have a binary kernel
	# built.
	cp -a ${WORKDIR}/out/* ${D}/ || die "couldn't copy output files into place"
	# module symlink fixup:
	rm -f ${D}/lib/modules/*/source || die
	rm -f ${D}/lib/modules/*/build || die
	cd ${D}/lib/modules
	local moddir="$(ls -d 2*)"
	ln -s /usr/src/linux-${P} ${D}/lib/modules/${moddir}/source || die
	ln -s /usr/src/linux-${P} ${D}/lib/modules/${moddir}/build || die
}

pkg_postinst() {
	# if K_EXTRAEINFO is set then lets display it now
	if [[ -n ${K_EXTRAEINFO} ]]; then
		echo ${K_EXTRAEINFO} | fmt |
		while read -s ELINE; do	einfo "${ELINE}"; done
	fi
	if [ ! -e ${ROOT}usr/src/linux ]
	then
		ln -s linux-${P} ${ROOT}usr/src/linux
	fi
}
