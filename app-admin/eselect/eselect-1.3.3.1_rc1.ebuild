# Distributed under the terms of the GNU General Public License v2

EAPI=3

inherit bash-completion-r1

DESCRIPTION="Gentoo's multi-purpose configuration and management tool"
HOMEPAGE="http://www.gentoo.org/proj/en/eselect/"
SRC_URI="mirror://gentoo/eselect-1.3.3.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~*"
IUSE="doc"
S=$WORKDIR/eselect-1.3.3

RDEPEND="sys-apps/sed
	|| (
		sys-apps/coreutils
		sys-freebsd/freebsd-bin
		app-misc/realpath
	)"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	doc? ( dev-python/docutils )"
RDEPEND="!app-admin/eselect-news
	${RDEPEND}
	sys-apps/file
	sys-libs/ncurses"

# Commented out: only few users of eselect will edit its source
#PDEPEND="emacs? ( app-emacs/gentoo-syntax )
#	vim-syntax? ( app-vim/eselect-syntax )"

src_compile() {
	emake || die

	if use doc; then
		emake html || die
	fi
}

src_install() {
	emake DESTDIR="${D}" install || die
	newbashcomp misc/${PN}.bashcomp ${PN} || die
	dodoc AUTHORS ChangeLog NEWS README TODO doc/*.txt || die

	if use doc; then
		dohtml *.html doc/* || die
	fi

	# needed by news module
	keepdir /var/lib/gentoo/news
	fowners root:portage /var/lib/gentoo/news || die
	fperms g+w /var/lib/gentoo/news || die

	# tweaks for funtoo-1.0 profile
	insinto /usr/share/eselect/modules
	doins $FILESDIR/$PVR/profile.eselect || die
	doins $FILESDIR/$PVR/kernel.eselect || die
}

pkg_postinst() {
	# fowners in src_install doesn't work for the portage group:
	# merging changes the group back to root
	[[ -z ${EROOT} ]] && local EROOT=${ROOT}
	chgrp portage "${EROOT}/var/lib/gentoo/news" \
		&& chmod g+w "${EROOT}/var/lib/gentoo/news"

	ewarn "This version of eselect supports using /etc/portage/make.profile along with the new Funtoo 1.0 profiles."
	ewarn "Please visit http://www.funtoo.org/wiki/Funtoo_1.0_Profile for instructions on how to switch"
}
