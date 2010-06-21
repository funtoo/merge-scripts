# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit subversion

DESCRIPTION="An auto-updater daemon for the Music Player Daemon"
HOMEPAGE="http://sarine.nl/"
ESVN_REPO_URI="https://svn.musicpd.org/${PN}/trunk"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86"
IUSE=""

DEPEND="media-libs/libmpd
	media-sound/mpd"
RDEPEND="${DEPEND}"

src_compile() {
	## Sane defaults
	sed -ie 's%cfg = cfg_open("config.cfg");%cfg = cfg_open("/etc/mpd-updater.conf");%' main.c || die "Died sedding 1"
	sed -ie 's%path=.*%path="/var/lib/mpd/music"%' config.cfg || die "Died sedding 2"
	sed -ie 's%hostname.*%hostname="127.0.0.1"%' config.cfg || die "Died sedding 3"
	sed -ie 's%password.*%password=""%' config.cfg || die "Died sedding 4"

	emake || die "Couldn't make"
}

src_install() {
	mv config.cfg mpd-updater.conf || die "Died moving"
	insinto /etc
	doins mpd-updater.conf
	exeinto /etc/init.d
	doexe ${FILESDIR}/mpd-updater

	dobin mpd-updater
}

pkg_postinst() {
	ewarn "*** This is a hack, it is by no means final code, it is a proof of concept that happens to work ***"
	ewarn "Don't think this is reliable or secure, though it does work."
	ewarn "Feel free to contact the author about this package, but don't expect support."
	ewarn "This will possibly be rewritten in the future."
}
