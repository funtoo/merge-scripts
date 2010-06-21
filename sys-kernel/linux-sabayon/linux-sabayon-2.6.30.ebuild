# Copyright 2004-2009 Sabayon Linux
# Distributed under the terms of the GNU General Public License v2

ETYPE="sources"
K_WANT_GENPATCHES=""
K_GENPATCHES_VER=""
K_SABPATCHES_VER="3"
K_SABPATCHES_PKG="${PV}-${K_SABPATCHES_VER}.tar.bz2"
inherit kernel-2 sabayon-artwork mount-boot linux-mod
detect_version
detect_arch

DESCRIPTION="Official Sabayon Linux Standard kernel image"
RESTRICT="mirror"
IUSE="splash dmraid grub"
UNIPATCH_STRICTORDER="yes"
KEYWORDS="~amd64 ~x86"
HOMEPAGE="http://www.sabayonlinux.org"

SRC_URI="${KERNEL_URI}
	http://distfiles.sabayonlinux.org/${CATEGORY}/linux-sabayon-patches/${K_SABPATCHES_PKG}"
DEPEND="${DEPEND}
	<sys-kernel/genkernel-3.4.11
	splash? ( x11-themes/sabayon-artwork-core )"
RDEPEND="grub? ( sys-boot/grub sys-boot/grub-handler )"

KV_FULL=${KV_FULL/linux/sabayon}
K_NOSETEXTRAVERSION="1"
EXTRAVERSION=${EXTRAVERSION/linux/sabayon}
SLOT="${PV}"
S="${WORKDIR}/linux-${KV_FULL}"

# patches
UNIPATCH_LIST="${DISTFILES}/${K_SABPATCHES_PKG}"

src_unpack() {

	kernel-2_src_unpack
	cd "${S}"

	# manually set extraversion
	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${EXTRAVERSION}:" Makefile

}

src_compile() {

	# disable sandbox
	export SANDBOX_ON=0
	export LDFLAGS=""

	# creating workdirs
	mkdir ${WORKDIR}/lib
	mkdir ${WORKDIR}/cache
	mkdir ${S}/temp
	# needed anyway, even if grub use flag is not used here
	mkdir -p ${WORKDIR}/boot/grub

	einfo "Starting to compile kernel..."
	cp ${FILESDIR}/${PF/-r0/}-${ARCH}.config ${WORKDIR}/config || die "cannot copy kernel config"

	# do some cleanup
	rm -rf "${WORKDIR}"/lib
	rm -rf "${WORKDIR}"/cache
	rm -rf "${S}"/temp
	OLDARCH=${ARCH}
	unset ARCH
	cd ${S}
	GK_ARGS="--disklabel"
	use splash && GKARGS="${GKARGS} --splash=sabayon"
	use dmraid && GKARGS="${GKARGS} --dmraid"
	export DEFAULT_KERNEL_SOURCE="${S}"
	export CMD_KERNEL_DIR="${S}"
	DEFAULT_KERNEL_SOURCE="${S}" CMD_KERNEL_DIR="${S}" genkernel ${GKARGS} \
		--kerneldir=${S} \
		--kernel-config=${WORKDIR}/config \
		--cachedir=${WORKDIR}/cache \
		--makeopts=-j3 \
		--tempdir=${S}/temp \
		--logfile=${WORKDIR}/genkernel.log \
		--bootdir=${WORKDIR}/boot \
		--mountboot \
		--lvm \
		--luks \
		--disklabel \
		--module-prefix=${WORKDIR}/lib \
		all || die "genkernel failed"
	ARCH=${OLDARCH}

}

src_install() {

	dodir "/usr/src/linux-${KV_FULL}"
	insinto "/usr/src/linux-${KV_FULL}"

	cp "${FILESDIR}/${PF/-r0/}-${OLDARCH}.config" .config
	doins ".config" || die "cannot copy kernel config"
	doins Module.symvers || die "cannot copy Module.symvers"
	doins System.map || die "cannot copy System.map"

	insinto "/boot"
	doins "${WORKDIR}"/boot/*
	cp -Rp "${WORKDIR}"/lib/* "${D}/"
	rm "${D}/lib/modules/${KV_FULL}/source"
	rm "${D}/lib/modules/${KV_FULL}/build"

	dosym "../../../usr/src/linux-${KV_FULL}" "/lib/modules/${KV_FULL}/source" || die "cannot install source symlink"
	dosym "../../../usr/src/linux-${KV_FULL}" "/lib/modules/${KV_FULL}/build" || die "cannot install build symlink"

}

pkg_setup() {
	# do not run linux-mod-pkg_setup
	einfo "Preparing to build the kernel and its modules"
}

pkg_preinst() {
	mount-boot_mount_boot_partition
	linux-mod_pkg_preinst
	UPDATE_MODULEDB=false

	# Workaround kernel issue with colliding
	# firmwares across different kernel versions
	for fwfile in `find "${D}/lib/firmware" -type f`; do

		sysfile="/lib/firmware/$(basename ${fwfile})"
		if [ -f "${sysfile}" ]; then
			ewarn "Removing duplicated: ${sysfile}"
			rm ${sysfile} || die "failed to remove ${sysfile}"
		fi

	done

}

pkg_postinst() {

	fstab_file="${ROOT}/etc/fstab"
	einfo "Removing extents option for ext4 drives from ${fstab_file}"
	# Remove "extents" from /etc/fstab
	if [ -f "${fstab_file}" ]; then
		sed -i '/ext4/ s/extents//g' ${fstab_file}
	fi

	# Update kernel initramfs to match user customizations
	update_sabayon_kernel_initramfs_splash

	# Add kernel to grub.conf
	if use grub; then
		if use amd64; then
			local kern_arch="x86_64"
		else
			local kern_arch="x86"
		fi
		/usr/sbin/grub-handler add \
			"/boot/kernel-genkernel-${kern_arch}-${KV_FULL}" \
			"/boot/initramfs-genkernel-${kern_arch}-${KV_FULL}"
	fi

	kernel-2_pkg_postinst
	linux-mod_pkg_postinst

	einfo "Please report kernel bugs at:"
	einfo "http://bugs.sabayonlinux.org"

	ewarn "The Sabayon Linux kernel source code is now located at"
	ewarn "=sys-kernel/linux-sabayon-sources-${PVR}."
	ewarn "Sabayon Linux recommends that portage users install"
	ewarn "sys-kernel/linux-sabayon-sources-${PVR} if you want"
	ewarn "to build any packages that install kernel modules"
	ewarn "(such as ati-drivers, nvidia-drivers, virtualbox, etc...)."

}

pkg_postrm() {

	# Add kernel to grub.conf
	if use grub; then
		if use amd64; then
			local kern_arch="x86_64"
		else
			local kern_arch="x86"
		fi
		/usr/sbin/grub-handler remove \
			"/boot/kernel-genkernel-${kern_arch}-${KV_FULL}" \
			"/boot/initramfs-genkernel-${kern_arch}-${KV_FULL}"
	fi

	linux-mod_pkg_postrm

}
