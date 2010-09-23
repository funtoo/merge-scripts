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
# for example, of linux-sabayon it is "${PN/${PN/-*}-}" (sabayon)
K_SABKERNEL_NAME="${K_SABKERNEL_NAME:-${PN/${PN/-*}-}}"

# @ECLASS-VARIABLE: K_SABKERNEL_URI_CONFIG
# @DESCRIPTION:
# Set this either to "no" or "yes" depending on the location of the
# kernel config files.  If they are inside FILESDIR (old location)
# leave this option set to "no", otherwise set this to "yes"
K_SABKERNEL_URI_CONFIG="${K_SABKERNEL_URI_CONFIG:-no}"

# @ECLASS-VARIABLE: K_KERNEL_SOURCES_PKG
# @DESCRIPTION:
# The kernel sources package used to build this kernel binary
K_KERNEL_SOURCES_PKG="${K_KERNEL_SOURCES_PKG:-${CATEGORY}/${PN/*-}-sources-${PVR}}"

# @ECLASS-VARIABLE: K_KERNEL_PATCH_VER
# @DESCRIPTION:
# If set to "3" for example, it applies the upstream kernel
# patch corresponding to patch-${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}.3.bz2
K_KERNEL_PATCH_VER="${K_KERNEL_PATCH_VER:-}"

# @ECLASS-VARIABLE: K_KERNEL_PATCH_HOTFIXES
# @DESCRIPTION:
# If there is the need to quickly apply patches to the kernel
# without bumping the kernel patch tarball (for eg. in case
# of just released security fixes), set this variable in your ebuild
# pointing to space separated list of patch paths.
K_KERNEL_PATCH_HOTFIXES="${K_KERNEL_PATCH_HOTFIXES:-}"

# @ECLASS-VARIABLE: K_KERNEL_DISABLE_PR_EXTRAVERSION
# @DESCRIPTION:
# Set this to "1" if you want to tell kernel-2 eclass to
# not use ${PR} in kernel EXTRAVERSION (K_NOUSEPR). Otherwise, set
# this to "0" to not set K_NOUSEPR at all.
K_KERNEL_DISABLE_PR_EXTRAVERSION="${K_KERNEL_DISABLE_PR_EXTRAVERSION:-1}"

# @ECLASS-VARIABLE: K_KERNEL_SLOT_USEPVR
# @DESCRIPTION:
# Set this to "1" if you want to use ${PVR} in SLOT variable, instead of ${PV}
# sys-kernel/linux-vserver (vserver-sources) require this. This won't work for
# firmware pkgs.
K_KERNEL_SLOT_USEPVR="${K_KERNEL_SLOT_USEPVR:-0}"

# @ECLASS-VARIABLE: K_SABKERNEL_FIRMWARE
# @DESCRIPTION:
# Set this to "1" if your ebuild is a kernel firmware package
K_FIRMWARE_PACKAGE="${K_FIRMWARE_PACKAGE:-}"

# @ECLASS-VARIABLE: K_ONLY_SOURCES
# @DESCRIPTION:
# For every kernel binary package, there is a kernel source package associated
# if your ebuild is one of them, set this to "1"
K_ONLY_SOURCES="${K_ONLY_SOURCES:-}"

# @ECLASS-VARIABLE: K_WORKAROUND_SOURCES_COLLISION
# @DESCRIPTION:
# For kernel binary packages, Workaround file collisions with kernel
# sources already providing certain files (like Makefile). Used
# by linux-openvz and linux-vserver
K_WORKAROUND_SOURCES_COLLISION="${K_WORKAROUND_SOURCES_COLLISION:-}"

# @ECLASS-VARIABLE: K_WORKAROUND_DIFFERENT_EXTRAVERSION
# @DESCRIPTION:
# Some kernel sources are shipped with their own EXTRAVERSION and
# we're kindly asked to not touch it, if this is your case, set
# this variable in order to make linux-mod_pkg_postinst happy
# (update_depmod) by feeding it with valid KV_FULL, that will be
# calculated using EXTRAVERSION in Makefile.
K_WORKAROUND_DIFFERENT_EXTRAVERSION="${K_WORKAROUND_DIFFERENT_EXTRAVERSION:-}"

KERN_INITRAMFS_SEARCH_NAME="${KERN_INITRAMFS_SEARCH_NAME:-initramfs-genkernel*${K_SABKERNEL_NAME}}"

# Disable deblobbing feature
K_DEBLOB_AVAILABLE=0

inherit eutils kernel-2 sabayon-artwork mount-boot linux-mod

# from kernel-2 eclass
detect_version
detect_arch

DESCRIPTION="Sabayon Linux kernel functions and phases"

## kernel-2 eclass settings
if [ -n "${K_SABPATCHES_VER}" ]; then
	UNIPATCH_STRICTORDER="yes"
	K_SABPATCHES_PKG="${PV}-${K_SABPATCHES_VER}.tar.bz2"
	UNIPATCH_LIST="${DISTFILES}/${K_SABPATCHES_PKG}"
	SRC_URI="${KERNEL_URI}
		http://distfiles.sabayon.org/${CATEGORY}/linux-sabayon-patches/${K_SABPATCHES_PKG}"
else
	SRC_URI="${KERNEL_URI}"
fi

if [ -n "${K_KERNEL_PATCH_VER}" ]; then
	K_PATCH_NAME="patch-${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}.${K_KERNEL_PATCH_VER}.bz2"
	SRC_URI="${SRC_URI}
		mirror://kernel/linux/kernel/v${KV_MAJOR}.${KV_MINOR}/${K_PATCH_NAME}"
	UNIPATCH_LIST="${DISTDIR}/${K_PATCH_NAME}
		${UNIPATCH_LIST}"
fi
if [ -n "${K_KERNEL_PATCH_HOTFIXES}" ]; then
	UNIPATCH_LIST="${K_KERNEL_PATCH_HOTFIXES} ${UNIPATCH_LIST}"
fi

# replace "linux" with K_SABKERNEL_NAME, usually replaces
# "linux" with "sabayon" or "server" or "openvz"
KV_FULL="${KV_FULL/${PN/-*}/${K_SABKERNEL_NAME}}"
EXTRAVERSION="${EXTRAVERSION/${PN/-*}/${K_SABKERNEL_NAME}}"
# drop -rX if exists
[[ -n "${PR//r0}" ]] && [[ "${K_KERNEL_DISABLE_PR_EXTRAVERSION}" = "1" ]] && \
	EXTRAVERSION="${EXTRAVERSION/-r*}" && KV_FULL="${KV_FULL/-r*}" && \
	KV="${KV/-r*}"
KV_OUT_DIR="/usr/src/linux-${KV_FULL}"
S="${WORKDIR}/linux-${KV_FULL}"


if [ -n "${K_FIRMWARE_PACKAGE}" ]; then
	SLOT="0"
elif [ "${K_KERNEL_SLOT_USEPVR}" = "1" ]; then
	SLOT="${PVR}"
else
	SLOT="${PV}"
fi

# provide extra virtual pkg
if [ -z "${K_FIRMWARE_PACKAGE}" ]; then
	PROVIDE="${PROVIDE} virtual/linux-binary"
fi

HOMEPAGE="http://www.sabayon.org"
if [ "${K_SABKERNEL_URI_CONFIG}" = "yes" ]; then
	K_SABKERNEL_CONFIG_FILE="${K_SABKERNEL_CONFIG_FILE:-${K_SABKERNEL_NAME}-${PVR}-__ARCH__.config}"
	SRC_URI="${SRC_URI}
		amd64? ( http://distfiles.sabayon.org/${CATEGORY}/linux-sabayon-patches/config/${K_SABKERNEL_CONFIG_FILE/__ARCH__/amd64} )
		x86? ( http://distfiles.sabayon.org/${CATEGORY}/linux-sabayon-patches/config/${K_SABKERNEL_CONFIG_FILE/__ARCH__/x86} )"
	use amd64 && K_SABKERNEL_CONFIG_FILE=${K_SABKERNEL_CONFIG_FILE/__ARCH__/amd64}
	use x86 && K_SABKERNEL_CONFIG_FILE=${K_SABKERNEL_CONFIG_FILE/__ARCH__/x86}
else
	use amd64 && K_SABKERNEL_CONFIG_FILE="${K_SABKERNEL_CONFIG_FILE:-${K_SABKERNEL_NAME}-${PVR}-amd64.config}"
	use x86 && K_SABKERNEL_CONFIG_FILE="${K_SABKERNEL_CONFIG_FILE:-${K_SABKERNEL_NAME}-${PVR}-x86.config}"
fi

if [ -n "${K_ONLY_SOURCES}" ] || [ -n "${K_FIRMWARE_PACKAGE}" ]; then
	IUSE="${IUSE}"
	DEPEND="sys-apps/sed"
	RDEPEND="${RDEPEND}"
else
	IUSE="dmraid dracut grub splash"
	DEPEND="sys-apps/sed
		app-arch/xz-utils
		sys-kernel/genkernel
		splash? ( x11-themes/sabayon-artwork-core )
		dracut? ( sys-kernel/dracut )"
	# FIXME: when grub-legacy will be removed, remove sys-boot/grub-handler
	RDEPEND="grub? ( || ( >=sys-boot/grub-1.98 ( <sys-boot/grub-1 sys-boot/grub-handler ) ) )
		sys-apps/sed
		>=sys-kernel/linux-firmwares-${PV}"
fi

sabayon-kernel_pkg_setup() {
	# do not run linux-mod-pkg_setup
	if [ -n "${K_FIRMWARE_PACKAGE}" ]; then
		einfo "Preparing to build kernel firmwares"
	else
		einfo "Preparing to build the kernel and its modules"
	fi
}

sabayon-kernel_src_compile() {
	if [ -n "${K_FIRMWARE_PACKAGE}" ]; then
		_firmwares_src_compile
	elif [ -n "${K_ONLY_SOURCES}" ]; then
		kernel-2_src_compile
	else
		_kernel_src_compile
	fi
}

_firmwares_src_compile() {
	einfo "Starting to compile firmwares..."
	_kernel_copy_config "${S}/.config"
	cd "${S}" || die "cannot find source dir"

	export LDFLAGS=""
	OLDARCH="${ARCH}"
	unset ARCH
	emake firmware || die "cannot compile firmwares"
	ARCH="${OLDARCH}"
}

_kernel_copy_config() {
	if [ "${K_SABKERNEL_URI_CONFIG}" = "no" ]; then
		cp "${FILESDIR}/${PF/-r0/}-${ARCH}.config" "${1}" || die "cannot copy kernel config"
	else
		cp "${DISTDIR}/${K_SABKERNEL_CONFIG_FILE}" "${1}" || die "cannot copy kernel config"
	fi
}

_kernel_src_compile() {
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
	_kernel_copy_config "${WORKDIR}"/config

	# do some cleanup
	rm -rf "${WORKDIR}"/lib
	rm -rf "${WORKDIR}"/cache
	rm -rf "${S}"/temp
	OLDARCH="${ARCH}"
	unset ARCH
	cd "${S}"
	GKARGS="--disklabel"
	use dracut && GKARGS="${GKARGS} --dracut"
	use splash && GKARGS="${GKARGS} --splash=sabayon"
	use dmraid && GKARGS="${GKARGS} --dmraid"
	export DEFAULT_KERNEL_SOURCE="${S}"
	export CMD_KERNEL_DIR="${S}"
	for opt in ${MAKEOPTS}; do
		if [ "${opt:0:2}" = "-j" ]; then
			mkopts="${opt}"
			break
		fi
	done
	[ -z "${mkopts}" ] && mkopts="-j3"

	DEFAULT_KERNEL_SOURCE="${S}" CMD_KERNEL_DIR="${S}" genkernel ${GKARGS} \
		--kerneldir="${S}" \
		--kernel-config="${WORKDIR}"/config \
		--cachedir="${WORKDIR}"/cache \
		--makeopts="${mkopts}" \
		--tempdir="${S}"/temp \
		--logfile="${WORKDIR}"/genkernel.log \
		--bootdir="${WORKDIR}"/boot \
		--mountboot \
		--lvm \
		--luks \
		--iscsi \
		--module-prefix="${WORKDIR}"/lib \
		all || die "genkernel failed"
	ARCH=${OLDARCH}
}

sabayon-kernel_src_install() {
        if [ -n "${K_FIRMWARE_PACKAGE}" ]; then
                _firmwares_src_install
        elif [ -n "${K_ONLY_SOURCES}" ]; then
		_kernel_sources_src_install
        else
		_kernel_src_install
	fi
}

_firmwares_src_install() {
	dodir /lib/firmware
	keepdir /lib/firmware
	( cd "${S}" && emake INSTALL_FW_PATH="${D}/lib/firmware" firmware_install ) || die "cannot install firmwares"
}

_kernel_sources_src_install() {
	local version_h_name="usr/src/linux-${KV_FULL}/include/linux"
	local version_h="${ROOT}${version_h_name}"
	if [ -f "${version_h}" ]; then
		einfo "Discarding previously installed version.h to avoid collisions"
		addwrite "/${version_h_name}"
		rm -f "${version_h}"
	fi

	kernel-2_src_install
	cd "${D}/usr/src/linux-${KV_FULL}"
	local oldarch="${ARCH}"
	cp "${DISTDIR}/${K_SABKERNEL_CONFIG_FILE}" .config || die "cannot copy kernel config"
	unset ARCH
	if ! use sources_standalone; then
		make modules_prepare || die "failed to run modules_prepare"
		rm .config || die "cannot remove .config"
		rm Makefile || die "cannot remove Makefile"
		rm include/linux/version.h || die "cannot remove include/linux/version.h"
	fi
	ARCH="${oldarch}"
}

_kernel_src_install() {
	dodir "${KV_OUT_DIR}"
	insinto "${KV_OUT_DIR}"

        if [ "${K_SABKERNEL_URI_CONFIG}" = "no" ]; then
		cp "${FILESDIR}/${PF/-r0/}-${OLDARCH}.config" .config || die "cannot copy kernel config"
        else
                cp "${DISTDIR}/${K_SABKERNEL_CONFIG_FILE}" .config || die "cannot copy kernel config"
        fi
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
	dodir "${KV_OUT_DIR}/include/linux"
	insinto "${KV_OUT_DIR}/include/linux"
	doins "${S}/include/linux/version.h" || die "cannot copy version.h"

	insinto "/boot"
	doins "${WORKDIR}"/boot/*
	cp -Rp "${WORKDIR}"/lib/* "${D}/"

	# This doesn't always work because KV_FULL (when K_NOSETEXTRAVERSION=1) doesn't
	# reflect the real value used in Makefile
	#dosym "../../..${KV_OUT_DIR}" "/lib/modules/${KV_FULL}/source" || die "cannot install source symlink"
	#dosym "../../..${KV_OUT_DIR}" "/lib/modules/${KV_FULL}/build" || die "cannot install build symlink"
	cd "${D}"/lib/modules/* || die "cannot enter /lib/modules directory, more than one element?"
	# cleanup previous
	rm -f build source || die
	# create sane symlinks
	ln -sf "../../..${KV_OUT_DIR}" source || die "cannot create source symlink"
	ln -sf "../../..${KV_OUT_DIR}" build || die "cannot create build symlink"
	cd "${S}"

	# drop ${D}/lib/firmware, virtual/linux-firmwares provides it
	rm -rf "${D}/lib/firmware"

	if [ -n "${K_WORKAROUND_SOURCES_COLLISION}" ]; then
		# Fixing up Makefile collision if already installed by
		# openvz-sources
		einfo "Workarounding source package collisions"
		make_file="usr/src/linux-${KV_FULL}/Makefile"
		einfo "Makefile: ${make_file}"
		if [ -f "${ROOT}/${make_file}" ]; then
			elog "Removing ${D}/${make_file}"
			rm -f "${D}/${make_file}"
		fi
	fi

}

_get_real_extraversion() {
	make_file="${ROOT}${KV_OUT_DIR}/Makefile"
	local extraver=$(grep -r "^EXTRAVERSION" "${make_file}" | cut -d "=" -f 2)
	local trimmed=${extraver%% }
	echo ${trimmed## }
}

sabayon-kernel_pkg_preinst() {
	if [ -z "${K_ONLY_SOURCES}" ] && [ -z "${K_FIRMWARE_PACKAGE}" ]; then
		mount-boot_pkg_preinst
		linux-mod_pkg_preinst
		UPDATE_MODULEDB=false
	fi
}
sabayon-kernel_grub2_mkconfig() {
	if [ -x "${ROOT}sbin/grub-mkconfig" ]; then
		"${ROOT}sbin/grub-mkdevicemap" --device-map="${ROOT}boot/grub/device.map"
		"${ROOT}sbin/grub-mkconfig" -o "${ROOT}boot/grub/grub.cfg"
	fi
}

sabayon-kernel_pkg_postinst() {
	if [ -z "${K_ONLY_SOURCES}" ] && [ -z "${K_FIRMWARE_PACKAGE}" ]; then
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
			if [ -x "${ROOT}usr/sbin/grub-handler" ]; then
				"${ROOT}usr/sbin/grub-handler" add \
					"/boot/kernel-genkernel-${kern_arch}-${KV_FULL}" \
					"/boot/initramfs-genkernel-${kern_arch}-${KV_FULL}"
			fi

			sabayon-kernel_grub2_mkconfig
		fi

		kernel-2_pkg_postinst
		if [ -n "${K_WORKAROUND_DIFFERENT_EXTRAVERSION}" ]; then
			UPDATE_DEPMOD="false"
			local depmod_r="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}$(_get_real_extraversion)"
			einfo "Updating (overridden) modules dependencies using ${depmod_r}"
			[[ -r "${KV_OUT_DIR}"/System.map ]] && \
				depmod -ae -F "${KV_OUT_DIR}"/System.map -b "${ROOT}" \
					-r "${depmod_r}"
		fi
		linux-mod_pkg_postinst

		elog "Please report kernel bugs at:"
		elog "http://bugs.sabayon.org"

		elog "The source code of this kernel is located at"
		elog "=${K_KERNEL_SOURCES_PKG}."
		elog "Sabayon Linux recommends that portage users install"
		elog "${K_KERNEL_SOURCES_PKG} if you want"
		elog "to build any packages that install kernel modules"
		elog "(such as ati-drivers, nvidia-drivers, virtualbox, etc...)."
	else
		kernel-2_pkg_postinst
	fi
}

sabayon-kernel_pkg_prerm() {
        if [ -z "${K_ONLY_SOURCES}" ] && [ -z "${K_FIRMWARE_PACKAGE}" ]; then
		mount-boot_pkg_prerm
	fi
}

sabayon-kernel_pkg_postrm() {
	if [ -z "${K_ONLY_SOURCES}" ] && [ -z "${K_FIRMWARE_PACKAGE}" ]; then
		# Remove kernel from grub.conf
		if use grub; then
			if use amd64; then
				local kern_arch="x86_64"
			else
				local kern_arch="x86"
			fi
			if [ -x "${ROOT}usr/sbin/grub-handler" ]; then
				"${ROOT}usr/sbin/grub-handler" remove \
					"/boot/kernel-genkernel-${kern_arch}-${KV_FULL}" \
					"/boot/initramfs-genkernel-${kern_arch}-${KV_FULL}"
			fi

			sabayon-kernel_grub2_mkconfig
		fi

		linux-mod_pkg_postrm
	fi
}

# export all the available functions here
EXPORT_FUNCTIONS pkg_setup src_compile src_install pkg_preinst pkg_postinst pkg_prerm pkg_postrm

