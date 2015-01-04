# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/eselect-opengl/eselect-opengl-1.3.1-r1.ebuild,v 1.2 2015/01/03 23:34:59 mgorny Exp $

EAPI=5

inherit multilib

DESCRIPTION="Utility to change the OpenGL interface being used"
HOMEPAGE="http://www.gentoo.org/"

# Source:
# http://www.opengl.org/registry/api/glext.h
# http://www.opengl.org/registry/api/glxext.h
GLEXT="85"
GLXEXT="34"

MIRROR="http://dev.gentoo.org/~mattst88/distfiles"
SRC_URI="http://dev.gentoo.org/~mgorny/dist/opengl.eselect-${PV}.xz"
#	${MIRROR}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND="app-arch/xz-utils"
RDEPEND=">=app-admin/eselect-1.2.4
		 !<media-libs/mesa-10.3.4-r1
		 !=media-libs/mesa-10.3.5
		 !<x11-proto/glproto-1.4.17-r1
		 !<x11-base/xorg-server-1.16.2-r1
		 !<x11-drivers/ati-drivers-14.9-r2
		 !=x11-drivers/ati-drivers-14.12
		 !<=app-emulation/emul-linux-x86-opengl-20140508"

S=${WORKDIR}

pkg_pretend() {
	if grep -q -s "Section.*Files" \
		"${EROOT%/}"/etc/X11/xorg.conf
	then
		ewarn 'Your /etc/X11/xorg.conf seems to contain Section "Files". This is'
		ewarn 'known to break eselect-opengl-1.3*. If you need a custom Files setup,'
		ewarn 'please downgrade to <eselect-opengl-1.3. We are sorry for the issues,'
		ewarn 'we are working on a more permanent solution.'
	fi
}

pkg_preinst() {
	# we may be moving the config file, so get it early
	OLD_IMPL=$(eselect opengl show)
}

pkg_postinst() {
	if [[ -n "${OLD_IMPL}" && "${OLD_IMPL}" != '(none)' ]] ; then
		eselect opengl set "${OLD_IMPL}"
	fi
	if [[ -f ${EROOT}/etc/env.d/03opengl ]]; then
		# remove the old file, moved now
		rm -vf "${EROOT}"/etc/env.d/03opengl
	fi
}

src_prepare() {
	# don't die on Darwin users
	if [[ ${CHOST} == *-darwin* ]] ; then
		sed -i -e 's/libGL\.so/libGL.dylib/' opengl.eselect || die
	fi
}

src_install() {
	insinto "/usr/share/eselect/modules"
	newins opengl.eselect-${PV} opengl.eselect
#	doman opengl.eselect.5
}
