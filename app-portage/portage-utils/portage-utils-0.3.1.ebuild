# Distributed under the terms of the GNU General Public License v2

inherit flag-o-matic toolchain-funcs

DESCRIPTION="small and fast portage helper tools written in C"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE="static"

src_unpack() {
	unpack ${A}
	cd "${S}"
	sed -i -e 's:\[\[:[:' -e 's:\]\]:]:' Makefile
}

src_compile() {
	tc-export CC
	use static && append-ldflags -static
	emake || die
}

src_install() {
	emake install DESTDIR="${D}" || die
	prepalldocs

	exeinto /etc/portage/bin
	doexe "${FILESDIR}"/post_sync || die
	insinto /etc/portage/postsync.d
	doins "${FILESDIR}"/q-reinitialize || die
}

pkg_preinst() {
	# preserve +x bit on postsync files #301721
	local x
	pushd "${D}" >/dev/null
	for x in etc/portage/postsync.d/* ; do
		[[ -x ${ROOT}/${x} ]] && chmod +x "${x}"
	done
}

pkg_postinst() {
	elog "/etc/portage/postsync.d/q-reinitialize has been installed for convenience"
	elog "If you wish for it to be automatically run at the end of every --sync:"
	elog "   # chmod +x /etc/portage/postsync.d/q-reinitialize"
	elog "Normally this should only take a few seconds to run but file systems"
	elog "such as ext3 can take a lot longer.  To disable, simply do:"
	elog "   # chmod -x /etc/portage/postsync.d/q-reinitialize"
}
