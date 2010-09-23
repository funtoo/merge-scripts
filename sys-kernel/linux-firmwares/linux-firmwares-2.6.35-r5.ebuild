# Copyright 2004-2010 Sabayon Linux
# Distributed under the terms of the GNU General Public License v2

ETYPE="sources"
K_SABPATCHES_VER="9"
K_KERNEL_PATCH_VER="3"
K_SABKERNEL_URI_CONFIG="yes"
# Doesn't make any difference, but a valid kernel .config
# file is required in order to build kernel firmwares
K_SABKERNEL_NAME="sabayon"
K_FIRMWARE_PACKAGE="1"
inherit sabayon-kernel
KEYWORDS="~amd64 ~x86"
DESCRIPTION="Linux Kernel firmwares from kernel.org tarballs"
RESTRICT="mirror"
