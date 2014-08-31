# Distributed under the terms of the GNU General Public License v2

EAPI=3

inherit mount-boot

SLOT=$PVR
CKV=2.6.38
SYSRESC_REL="${PV##*.}"
KV_FULL=${PN}-${PVR}
KERNEL_ARCHIVE="linux-${CKV}.tar.bz2"
KERNEL_URI="mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/${KERNEL_ARCHIVE}"
RESTRICT="binchecks strip"

LICENSE="GPL-2"
KEYWORDS="x86 amd64"
IUSE="binary"
DEPEND="binary? ( >=sys-kernel/genkernel-3.4.12.6-r4 )"
DESCRIPTION="System Rescue CD Full sources for the Linux kernel, including gentoo and sysresccd patches."
HOMEPAGE="http://kernel.sysresccd.org"
SRC_URI="${KERNEL_URI} http://ftp.osuosl.org/pub/funtoo/distfiles/sysrescue-std-sources/std-sources-${PV}-patches-config.tar.xz"
S="$WORKDIR/linux-${CKV}"
S2="$WORKDIR/${SYSRESC_REL}"

src_unpack() {
	unpack ${KERNEL_ARCHIVE} std-sources-${PV}-patches-config.tar.xz
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
			defconfig_src=std${SYSRESC_REL}.i586
			;;
		amd64)
			defconfig_src=std${SYSRESC_REL}.x86_64
			;;
		*)
			die "unsupported ARCH: $ARCH"
			;;
	esac
	defconfig_src="${S2}/kernelcfg/config-${CKV}-${defconfig_src}"
	unset ARCH; unset LDFLAGS #will interfere with Makefile if set
}

src_prepare() {
	apply $S2/std-sources-2.6.38-01-stable-2.6.38.8.patch -p1
	apply $S2/std-sources-2.6.38-02-fc15-030.patch -p1
	apply $S2/std-sources-2.6.38-03-aufs.patch -p1
	apply $S2/std-sources-2.6.38-04-reiser4.patch -p1
	apply $S2/std-sources-2.6.38-05-loopaes.patch -p1
	sedlockdep='s:.*#define MAX_LOCKDEP_SUBCLASSES.*8UL:#define MAX_LOCKDEP_SUBCLASSES 16UL:'
	sed -i -e "${sedlockdep}" include/linux/lockdep.h || die
	sednoagp='s:int nouveau_noagp;:int nouveau_noagp=1;:g'
	sed -i -e "${sednoagp}" drivers/gpu/drm/nouveau/nouveau_drv.c || die
	oldextra=$(cat Makefile | grep "^EXTRAVERSION")
	sed -i -e "s/${oldextra}/EXTRAVERSION = -sysrescue-std${SYSRESC_REL}/" Makefile || die
	cp $S2/kernelcfg/config-${CKV}-std${SYSRESC_REL}.x86_64 arch/x86/configs/x86_64_defconfig || die
	cp $S2/kernelcfg/config-${CKV}-std${SYSRESC_REL}.i586 arch/x86/configs/i386_defconfig || die
	rm -f .config >/dev/null
	make -s mrproper || die "make mrproper failed"
	make -s include/linux/version.h || die "make include/linux/version.h failed"
}

src_compile() {
	! use binary && return
	install -d ${WORKDIR}/out/{lib,boot}
	install -d ${T}/{cache,twork}
	install -d $WORKDIR/build $WORKDIR/out/lib/firmware
	genkernel ${GKARGS} \
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
	# if we didn't use genkernel, we're done:
	make mrproper || die
	cp $defconfig_src .config || die
	yes "" | make oldconfig || die
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
	# module strip:
	find -iname *.ko -exec strip --strip-debug {} \;
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
