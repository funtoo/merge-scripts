# Distributed under the terms of the GNU General Public License v2

EAPI="3"

inherit flag-o-matic toolchain-funcs eutils

DESCRIPTION="small and fast portage helper tools written in C"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="static"

src_prepare() {
	epatch "${FILESDIR}/${P}-funtoo-sync.patch"
}

src_configure() {
	use static && append-ldflags -static

	# Avoid slow configure+gnulib+make if on an up-to-date Linux system
	if use prefix || ! use kernel_linux || \
	   has_version '<sys-libs/glibc-2.10'
	then
		econf --with-eprefix="${EPREFIX}"
	else
		tc-export CC
	fi
}

src_install() {
	emake install DESTDIR="${D}" || die
	prepalldocs

	exeinto /etc/portage/bin
	doexe "${FILESDIR}"/post_sync || die
	insinto /etc/portage/postsync.d
	doins "${FILESDIR}"/q-reinitialize || die

	# Portage fixes shebangs, we just need to fix the paths in the files
	sed -i \
		-e "s:\(/etc/portage/postsync.d\|/usr/bin/q\):${EPREFIX}&:g" \
		"${ED}"/etc/portage/bin/post_sync \
		"${ED}"/etc/portage/postsync.d/q-reinitialize || die
}

pkg_preinst() {
	# preserve +x bit on postsync files #301721
	local x
	pushd "${ED}" >/dev/null
	for x in etc/portage/postsync.d/* ; do
		[[ -x ${EROOT}/${x} ]] && chmod +x "${x}"
	done
}

pkg_postinst() {
	elog "${EPREFIX}/etc/portage/postsync.d/q-reinitialize has been installed for convenience"
	elog "If you wish for it to be automatically run at the end of every --sync:"
	elog "   # chmod +x ${EPREFIX}/etc/portage/postsync.d/q-reinitialize"
	elog "Normally this should only take a few seconds to run but file systems"
	elog "such as ext3 can take a lot longer.  To disable, simply do:"
	elog "   # chmod -x ${EPREFIX}/etc/portage/postsync.d/q-reinitialize"
}
