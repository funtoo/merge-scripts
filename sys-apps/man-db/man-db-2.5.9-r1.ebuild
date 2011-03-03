# Copyright 1999-2011 Gentoo Foundation, Funtoo Technologies
# Distributed under the terms of the GNU General Public License v2

EAPI="2"

inherit eutils

DESCRIPTION="a man replacement that utilizes berkdb instead of flat files"
HOMEPAGE="http://www.nongnu.org/man-db/"
SRC_URI="http://download.savannah.nongnu.org/releases/man-db/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc x86"
IUSE="berkdb +gdbm nls"
PROVIDE="virtual/man"

RDEPEND="berkdb? ( sys-libs/db )
	gdbm? ( sys-libs/gdbm )
	!berkdb? ( !gdbm? ( sys-libs/gdbm ) )
	|| ( sys-apps/groff >=app-doc/heirloom-doctools-080407-r2 )
	!sys-apps/man"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )"

pkg_setup() {
	enewgroup man 15
	enewuser man 13 -1 /usr/share/man man
}

src_configure() {
	local db="gdbm"
	use berkdb && ! use gdbm && db="db"
	econf \
		--with-sections="1 1p 8 2 3 3p 4 5 6 7 9 0p tcl n l p o 1x 2x 3x 4x 5x 6x 7x 8x" \
		$(use_enable nls) \
		--with-db=${db} \
		--docdir=/usr/share/doc/${PF} \
		--enable-setuid
}

src_install() {
	emake install DESTDIR="${D}" || die
	dodoc README ChangeLog NEWS docs/{HACKING,TODO}
	exeinto /etc/cron.daily
	newexe $FILESDIR/man-db.cron man-db || die
}

pkg_preinst() {
	if [ -f "${ROOT}var/cache/man/whatis" ]
	then
		einfo "Cleaning stale ${ROOT}var/cache/man directory..."
		rm -rf "${ROOT}var/cache/man"
	fi
	einfo "Ensuring ${ROOT}var/cache/man has correct permissions and ownership..."
	install -o man -g root -m2775 -d man:root "$ROOT/var/cache/man" || die
}

pkg_postinst() {
	if [ "$ROOT" = "/" ]
	then
		einfo "Generating/updating man-db cache..."
		/etc/cron.daily/man-db
	fi
}
