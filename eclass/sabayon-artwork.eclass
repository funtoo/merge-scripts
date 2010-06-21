# Copyright 2004-2009 Sabayon Project
# Distributed under the terms of the GNU General Public License v2
# $

inherit eutils

# @ECLASS-VARIABLE: KERN_INITRAMFS_SEARCH_NAME
# @DESCRIPTION:
# Argument used by `find` to search inside ${ROOT}boot Linux
# Kernel initramfs files to patch
KERN_INITRAMFS_SEARCH_NAME="${KERN_INITRAMFS_SEARCH_NAME:-initramfs-genkernel*sabayon}"

# @ECLASS-VARIABLE: GFX_SPLASH_NAME
# @DESCRIPTION:
# Default splash theme name to use
GFX_SPLASH_NAME="${GFX_SPLASH_NAME:-sabayon}"

# @FUNCTION: update_kernel_initramfs_splash
# @USAGE: update_kernel_initramfs_splash [splash_theme] [splash_file]
# @RETURN: 1, if something went wrong
#
# @MAINTAINER:
# Fabio Erculiani
update_kernel_initramfs_splash() {

	[[ -z "${2}" ]] && die "wrong update_kernel_splash arguments"

	if ! has_version "media-gfx/splashutils"; then
		ewarn "media-gfx/splashutils not found, cannot update kernel splash"
		return 1
	fi
	splash_geninitramfs -a "${2}" ${1}
	return ${?}

}

# @FUNCTION: update_sabayon_kernel_initramfs_splash
# @USAGE: update_sabayon_kernel_initramfs_splash
#
# @MAINTAINER:
# Fabio Erculiani
update_sabayon_kernel_initramfs_splash() {

        for bootfile in `find ${ROOT}boot -name "${KERN_INITRAMFS_SEARCH_NAME}"`; do
                einfo "Updating boot splash for ${bootfile}"
                update_kernel_initramfs_splash "${GFX_SPLASH_NAME}" "${bootfile}"
        done

}
