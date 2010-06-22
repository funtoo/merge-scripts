# Copyright 2006-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/profiles/base/profile.bashrc,v 1.6 2010/04/30 00:01:05 zmedico Exp $

# Skip this if PM_EBUILD_HOOK_DIR is set since this means that
# /etc/portage/env is supported by the package manager:
# http://git.overlays.gentoo.org/gitweb/?p=proj/portage.git;a=commit;h=ef2024a33be93a256beef28c1423ba1fb706383d
if [[ -z $PM_EBUILD_HOOK_DIR && \
	-d ${PORTAGE_CONFIGROOT}/etc/portage/env ]] ; then
	for conf in ${PN} ${PN}-${PV} ${PN}-${PV}-${PR}; do
		[[ -r ${PORTAGE_CONFIGROOT}/etc/portage/env/${CATEGORY}/${conf} ]] \
			&& . ${PORTAGE_CONFIGROOT}/etc/portage/env/${CATEGORY}/${conf}
	done
fi

if ! declare -F elog >/dev/null ; then
	elog() {
		einfo "$@"
	}
fi
