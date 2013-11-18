# Copyright (C) 2013 Jonathan Vasquez <jvasquez1011@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit eutils mount-boot

# Variables
_LV="FB.01"						# Local Version
_PLV="${PV}-${_LV}"				# Package Version + Local Version (Module Dir)
_KN="linux-${_PLV}"				# Kernel Directory Name
_KD="/usr/src/${_KN}"			# Kernel Directory
_CONF="bliss.conf"				# Blacklisted Kernel Modules

# Main
DESCRIPTION="Precompiled Vanilla Kernel (Kernel Ready-to-Eat [KRE])"
HOMEPAGE="http://funtoo.org/"
SRC_URI="http://ftp.osuosl.org/pub/funtoo/distfiles/${PN}/${_PLV}/kernel-${_PLV}.tar.bz2
		 http://ftp.osuosl.org/pub/funtoo/distfiles/${PN}/${_PLV}/modules-${_PLV}.tar.bz2
		 http://ftp.osuosl.org/pub/funtoo/distfiles/${PN}/${_PLV}/headers-${_PLV}.tar.bz2"

RESTRICT="mirror strip"
LICENSE="GPL-2"
SLOT="${_PLV}"
KEYWORDS="~amd64"

S="${WORKDIR}"

src_compile()
{
	# Unset ARCH so that you don't get Makefile not found messages
	unset ARCH && return;
}

src_install()
{
	# Install Kernel
	insinto /boot
	doins ${S}/kernel/*

	# Instal Modules
	dodir /lib/modules/
	cp -r ${S}/modules/${_PLV} ${D}/lib/modules

	# Install Headers
	dodir /usr/src
	cp -r ${S}/headers/${_KN} ${D}/usr/src

	# Install Blacklist
	insinto /etc/modprobe.d/
	doins ${FILESDIR}/${_CONF}
}

pkg_postinst()
{
	# Set the kernel symlink if /usr/src/linux doesn't exist
	# Do not create symlink via 'symlink' use flag. This package will be re-emerged
	# when an 'emerge @module-rebuild' is done. If a person does this and the symlink use flag
	# is set, it will change the symlink to this ebuild, possibly not recompiling packages that
	# are suppose to be recompiled for another kernel.
	if [[ ! -h "/usr/src/linux" ]]; then
		einfo "Creating symlink to ${_KD}"
		eselect kernel set ${_KN}
	fi
}
