# Distributed under the terms of the GNU General Public License v2

EAPI=2

inherit mount-boot

SLOT=$PVR
CKV=2.6.32
KV_FULL=${PN}-${PVR}
EXTRAVERSION=-42.95
KERNEL_ARCHIVE="linux-${CKV}.tar.bz2"
KERNEL_URI="mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/${KERNEL_ARCHIVE}"
RESTRICT="binchecks strip"

LICENSE="GPL-2"
KEYWORDS="*"
IUSE="binary"
DEPEND="binary? ( >=sys-kernel/genkernel-3.4.12.6-r4 ) =sys-devel/gcc-4.4.5*"
DESCRIPTION="Ubuntu Server sources (and optional binary kernel)"
HOMEPAGE="http://www.openvz.org"
MAINPATCH="linux_${CKV}${EXTRAVERSION}.diff.gz"
SRC_URI="${KERNEL_URI} http://archive.ubuntu.com/ubuntu/pool/main/l/linux/${MAINPATCH}"
S="$WORKDIR/linux-${CKV}"

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
	echo "Applying patch $p"; $ca $p | patch $* || die "patch $p failed"
}

pkg_setup() {
	case $ARCH in
		x86)
			defconfig_src=i386-config.flavour.generic-pae-full
			;;
		amd64)
			defconfig_src=amd64-config.flavour.server-full
			;;
		*)
			die "unsupported ARCH: $ARCH"
			;;
	esac
	defconfig_src="${S}/configs/${defconfig_src}"
	unset ARCH; unset LDFLAGS #will interfere with Makefile if set
}

src_prepare() {
	apply $DISTDIR/$MAINPATCH -p1
	apply $FILESDIR/$PVR/gcc-4.4.5.patch -p1

	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${EXTRAVERSION}:" Makefile || die
	sed	-i -e 's:#export\tINSTALL_PATH:export\tINSTALL_PATH:' Makefile || die
	rm -f .config >/dev/null

	# Ubuntu:

	chmod +x debian/scripts/config-check || die
	chmod +x debian/scripts/misc/splitconfig.pl || die
	chmod +x debian/scripts/misc/kernelconfig || die
	install -d ${TEMP}/configs || die
	sed -i -e 's:^tmpdir=.*$:tmpdir=$TEMP/configs:' debian/scripts/misc/kernelconfig || die

	DROOT="debian" debian/scripts/misc/kernelconfig defaultconfig || die

	make -s mrproper || die "make mrproper failed"
	make -s include/linux/version.h || die "make include/linux/version.h failed"

	mv "${TEMP}/configs" "${S}" || die
}

src_compile() {
	! use binary && return
	install -d ${WORKDIR}/out/{lib,boot}
	install -d ${T}/{cache,twork}
	install -d $WORKDIR/build $WORKDIR/out/lib/firmware
	DEFAULT_KERNEL_SOURCE="${S}" CMD_KERNEL_DIR="${S}" genkernel ${GKARGS} \
		--no-save-config \
		--kernel-config="$defconfig_src" \
		--kernname="${PN}" \
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
	# back to the symlink fixup:
	local moddir="$(ls -d 2*)"
	ln -s /usr/src/linux-${P} ${D}/lib/modules/${moddir}/source || die
	ln -s /usr/src/linux-${P} ${D}/lib/modules/${moddir}/build || die

	# Fixes FL-14
	cp "${WORKDIR}/build/System.map" "${D}/usr/src/linux-${P}/" || die
	cp "${WORKDIR}/build/Module.symvers" "${D}/usr/src/linux-${P}/" || die
}

pkg_postinst() {
	if [ ! -e ${ROOT}usr/src/linux ]
	then
		ln -s linux-${P} ${ROOT}usr/src/linux
	fi
}
