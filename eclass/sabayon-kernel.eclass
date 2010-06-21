# Copyright 2004-2010 Sabayon Project
# Distributed under the terms of the GNU General Public License v2
# $

# @ECLASS-VARIABLE: K_SABPATCHES_VER
# @DESCRIPTION:
# The version of the sabayon patches tarball(s) to apply.
# A value of "5" would apply 2.6.12-5 to my-sources-2.6.12.ebuild

# @ECLASS-VARIABLE: K_SABKERNEL_NAME
# @DESCRIPTION:
# The kernel name used by the ebuild, it should be the ending ${PN} part
# for example, of linux-sabayon it is "sabayon", for linux-server it is "server"
K_SABKERNEL_NAME="${K_SABKERNEL_NAME:-sabayon}"

# @ECLASS-VARIABLE: K_SABKERNEL_URI_CONFIG
# @DESCRIPTION:
# Set this either to "no" or "yes" depending on the location of kernel config files
# if they are inside FILESDIR (old location) leave this option set to "no", otherwise
# set this to "yes"
K_SABKERNEL_URI_CONFIG="${K_SABKERNEL_URI_CONFIG:-no}"

# @ECLASS-VARIABLE: K_KERNEL_SOURCES_PKG
# @DESCRIPTION:
# The kernel sources package used to build this kernel binary
K_KERNEL_SOURCES_PKG="${K_KERNEL_SOURCES_PKG:-${CATEGORY}/${PN}-sources-${PVR}}"

K_ONLY_SOURCES="${K_ONLY_SOURCES:-}"

KERN_INITRAMFS_SEARCH_NAME="${KERN_INITRAMFS_SEARCH_NAME:-initramfs-genkernel*${K_SABKERNEL_NAME}}"

# Disable deblobbing feature
K_DEBLOB_AVAILABLE=0

inherit eutils kernel-2 sabayon-artwork mount-boot linux-mod

# from kernel-2 eclass
detect_version
detect_arch

# export all the available functions here
EXPORT_FUNCTIONS pkg_setup src_unpack src_compile src_install pkg_preinst pkg_postinst pkg_postrm

DESCRIPTION="Sabayon Linux kernel functions and phases"

## kernel-2 eclass settings
K_NOSETEXTRAVERSION="1"
if [ -n "${K_SABPATCHES_VER}" ]; then
	UNIPATCH_STRICTORDER="yes"
	K_SABPATCHES_PKG="${PV}-${K_SABPATCHES_VER}.tar.bz2"
	UNIPATCH_LIST="${DISTFILES}/${K_SABPATCHES_PKG}"
fi

# ebuild default values setup settings
KV_FULL=${KV_FULL/linux/${K_SABKERNEL_NAME}}
MY_KERNEL_DIR="/usr/src/linux-${KV_FULL}"
KV_OUT_DIR="${MY_KERNEL_DIR}"
S="${WORKDIR}/linux-${KV_FULL}"
SLOT="${PV}"
EXTRAVERSION=${EXTRAVERSION/linux/${K_SABKERNEL_NAME}}

HOMEPAGE="http://www.sabayon.org"
SRC_URI="${KERNEL_URI}
	http://distfiles.sabayon.org/${CATEGORY}/linux-sabayon-patches/${K_SABPATCHES_PKG}"
if [ "${K_SABKERNEL_URI_CONFIG}" = "yes" ]; then
	K_SABKERNEL_CONFIG_FILE="${K_SABKERNEL_CONFIG_FILE:-${K_SABKERNEL_NAME}-${PVR}-__ARCH__.config}"
	SRC_URI="${SRC_URI}
		amd64? ( http://distfiles.sabayon.org/${CATEGORY}/linux-sabayon-patches/config/${K_SABKERNEL_CONFIG_FILE/__ARCH__/amd64} )
		x86? ( http://distfiles.sabayon.org/${CATEGORY}/linux-sabayon-patches/config/${K_SABKERNEL_CONFIG_FILE/__ARCH__/x86} )"
	use amd64 && K_SABKERNEL_CONFIG_FILE=${K_SABKERNEL_CONFIG_FILE/__ARCH__/amd64}
	use x86 && K_SABKERNEL_CONFIG_FILE=${K_SABKERNEL_CONFIG_FILE/__ARCH__/x86}
fi

if [ -n "${K_ONLY_SOURCES}" ]; then
	IUSE="${IUSE}"
	DEPEND="sys-apps/sed"
	RDEPEND="${RDEPEND}"
else
	IUSE="splash dmraid grub"
	DEPEND="sys-apps/sed
		app-arch/xz-utils
		<sys-kernel/genkernel-3.4.11
		splash? ( x11-themes/sabayon-artwork-core )"
	# FIXME: when grub-legacy will be removed, remove sys-boot/grub-handler
	RDEPEND="grub? ( || ( sys-boot/grub:2 ( sys-boot/grub:0 sys-boot/grub-handler ) ) )
		sys-apps/sed"
fi

sabayon-kernel_pkg_setup() {
	# do not run linux-mod-pkg_setup
	einfo "Preparing to build the kernel and its modules"
}

sabayon-kernel_src_unpack() {

	kernel-2_src_unpack
	cd "${S}"

	# manually set extraversion
	sed -i -e "s:^\(EXTRAVERSION =\).*:\1 ${EXTRAVERSION}:" Makefile

}

sabayon-kernel_src_compile() {
	# disable sandbox
	export SANDBOX_ON=0
	export LDFLAGS=""

	# creating workdirs
	mkdir "${WORKDIR}"/lib
	mkdir "${WORKDIR}"/cache
	mkdir "${S}"/temp
	# needed anyway, even if grub use flag is not used here
	mkdir -p "${WORKDIR}"/boot/grub

	einfo "Starting to compile kernel..."
	if [ "${K_SABKERNEL_URI_CONFIG}" = "no" ]; then
		cp "${FILESDIR}/${PF/-r0/}-${ARCH}.config" "${WORKDIR}"/config || die "cannot copy kernel config"
	else
		cp "${DISTDIR}/${K_SABKERNEL_CONFIG_FILE}" "${WORKDIR}"/config || die "cannot copy kernel config"
	fi

	# do some cleanup
	rm -rf "${WORKDIR}"/lib
	rm -rf "${WORKDIR}"/cache
	rm -rf "${S}"/temp
	OLDARCH="${ARCH}"
	unset ARCH
	cd "${S}"
	GK_ARGS="--disklabel"
	use splash && GKARGS="${GKARGS} --splash=sabayon"
	use dmraid && GKARGS="${GKARGS} --dmraid"
	export DEFAULT_KERNEL_SOURCE="${S}"
	export CMD_KERNEL_DIR="${S}"

	DEFAULT_KERNEL_SOURCE="${S}" CMD_KERNEL_DIR="${S}" genkernel ${GKARGS} \
		--kerneldir="${S}" \
		--kernel-config="${WORKDIR}"/config \
		--cachedir="${WORKDIR}"/cache \
		--makeopts="$MAKEOPTS" \
		--tempdir="${S}"/temp \
		--logfile="${WORKDIR}"/genkernel.log \
		--bootdir="${WORKDIR}"/boot \
		--mountboot \
		--lvm \
		--luks \
		--disklabel \
		--module-prefix="${WORKDIR}"/lib \
		all || die "genkernel failed"
	ARCH=${OLDARCH}
}

sabayon-kernel_src_install() {
	dodir "${MY_KERNEL_DIR}"
	insinto "${MY_KERNEL_DIR}"

	cp "${FILESDIR}/${PF/-r0/}-${OLDARCH}.config" .config
	doins ".config" || die "cannot copy kernel config"
	doins Makefile || die "cannot copy Makefile"
	doins Module.symvers || die "cannot copy Module.symvers"
	doins System.map || die "cannot copy System.map"

	# NOTE: this is a workaround caused by linux-info.eclass not
	# being ported to EAPI=2 yet
        local version_h_name="usr/src/linux-${KV_FULL}/include/linux"
        local version_h="${ROOT}${version_h_name}/version.h"
	if [ -f "${version_h}" ]; then
	        einfo "Discarding previously installed version.h to avoid collisions"
        	addwrite "${version_h}"
        	rm -f "${version_h}"
	fi

	# Include include/linux/version.h to make Portage happy
	dodir "${MY_KERNEL_DIR}/include/linux"
	insinto "${MY_KERNEL_DIR}/include/linux"
	doins "${S}/include/linux/version.h" || die "cannot copy version.h"

	insinto "/boot"
	doins "${WORKDIR}"/boot/*
	cp -Rp "${WORKDIR}"/lib/* "${D}/"

	dosym "../../..${MY_KERNEL_DIR}" "/lib/modules/${KV_FULL}/source" || die "cannot install source symlink"
	dosym "../../..${MY_KERNEL_DIR}" "/lib/modules/${KV_FULL}/build" || die "cannot install build symlink"

	addwrite "/lib/firmware"
	# Workaround kernel issue with colliding
	# firmwares across different kernel versions
	for fwfile in `find "${D}/lib/firmware" -type f`; do

		sysfile="${ROOT}${fwfile/${D}}"
		if [ -f "${sysfile}" ]; then
			ewarn "Removing duplicated: ${sysfile}"
			rm -f "${sysfile}"
		fi

	done
}

sabayon-kernel_pkg_preinst() {
	mount-boot_mount_boot_partition
	linux-mod_pkg_preinst
	UPDATE_MODULEDB=false
}

sabayon-kernel_grub2_mkconfig() {
	if [ -x "${ROOT}sbin/grub-mkconfig" ]; then
		"${ROOT}sbin/grub-mkdevicemap" --device-map="${ROOT}boot/grub/device.map"
		"${ROOT}sbin/grub-mkconfig" -o "${ROOT}boot/grub/grub.cfg"
	fi
}

sabayon-kernel_pkg_postinst() {
	fstab_file="${ROOT}etc/fstab"
	einfo "Removing extents option for ext4 drives from ${fstab_file}"
	# Remove "extents" from /etc/fstab
	if [ -f "${fstab_file}" ]; then
		sed -i '/ext4/ s/extents//g' "${fstab_file}"
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
		# grub-legacy
		"${ROOT}/usr/sbin/grub-handler" add \
			"/boot/kernel-genkernel-${kern_arch}-${KV_FULL}" \
			"/boot/initramfs-genkernel-${kern_arch}-${KV_FULL}"

		sabayon-kernel_grub2_mkconfig
	fi

	kernel-2_pkg_postinst
	linux-mod_pkg_postinst

	elog "Please report kernel bugs at:"
	elog "http://bugs.sabayon.org"

	elog "The source code of this kernel is located at"
	elog "=${K_KERNEL_SOURCES_PKG}."
	elog "Sabayon Linux recommends that portage users install"
	elog "${K_KERNEL_SOURCES_PKG} if you want"
	elog "to build any packages that install kernel modules"
	elog "(such as ati-drivers, nvidia-drivers, virtualbox, etc...)."
}

sabayon-kernel_pkg_postrm() {
	# Remove kernel from grub.conf
	if use grub; then
		if use amd64; then
			local kern_arch="x86_64"
		else
			local kern_arch="x86"
		fi
		/usr/sbin/grub-handler remove \
			"/boot/kernel-genkernel-${kern_arch}-${KV_FULL}" \
			"/boot/initramfs-genkernel-${kern_arch}-${KV_FULL}"

		sabayon-kernel_grub2_mkconfig
	fi

	linux-mod_pkg_postrm
}
