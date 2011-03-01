# Copyright 2006-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/profiles/base/profile.bashrc,v 1.4 2009/10/16 17:37:56 arfrever Exp $

if [[ ${EBUILD_PHASE} == "setup" ]]; then
	export PYTHONDONTWRITEBYTECODE="1"
fi

for conf in ${PN} ${PN}-${PV} ${PN}-${PV}-${PR}; do
	[[ -r ${PORTAGE_CONFIGROOT}/etc/portage/env/${CATEGORY}/${conf} ]] \
		&& . ${PORTAGE_CONFIGROOT}/etc/portage/env/${CATEGORY}/${conf}
done

if ! declare -F elog >/dev/null ; then
	elog() {
		einfo "$@"
	}
fi
