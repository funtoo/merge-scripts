# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-vim/gentoo-syntax/gentoo-syntax-20101212.ebuild,v 1.3 2011/05/03 09:34:13 grobian Exp $

inherit eutils vim-plugin

DESCRIPTION="vim plugin: Gentoo Ebuild, Eclass, GLEP, ChangeLog and Portage Files syntax highlighting, filetype and indent settings"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="vim"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="ignore-glep31"

VIM_PLUGIN_HELPFILES="gentoo-syntax"
VIM_PLUGIN_MESSAGES="filetype"

src_unpack() {
	unpack ${A}
	cd "${S}"

	if use ignore-glep31 ; then
		for f in ftplugin/*.vim ; do
			ebegin "Removing UTF-8 rules from ${f} ..."
			sed -i -e 's~\(setlocal fileencoding=utf-8\)~" \1~' ${f} \
				|| die "waah! bad sed voodoo. need more goats."
			eend $?
		done
	fi
}

pkg_postinst() {
	vim-plugin_pkg_postinst
	if use ignore-glep31 1>/dev/null ; then
		ewarn "You have chosen to disable the rules which ensure GLEP 31"
		ewarn "compliance. When editing ebuilds, please make sure you get"
		ewarn "the character set correct."
	else
		elog "Note for developers and anyone else who edits ebuilds:"
		elog "    This release of gentoo-syntax now contains filetype rules to set"
		elog "    fileencoding for ebuilds and ChangeLogs to utf-8 as per GLEP 31."
		elog "    If you find this feature breaks things, please submit a bug and"
		elog "    assign it to vim@gentoo.org. You can use the 'ignore-glep31' USE"
		elog "    flag to remove these rules."
	fi
	echo
}
