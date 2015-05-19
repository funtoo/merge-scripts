# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit toolchain-funcs user

DESCRIPTION="Console-based network traffic monitor that keeps statistics of network usage"
HOMEPAGE="http://humdi.net/vnstat/"
SRC_URI="http://humdi.net/vnstat/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="gd"

DEPEND="gd? ( media-libs/gd[png] )"
RDEPEND="${DEPEND}"

pkg_setup() {
	enewgroup vnstat
	enewuser vnstat -1 -1 /dev/null vnstat
}

src_prepare() {
	tc-export CC

	sed -i 's:^DaemonUser.*:DaemonUser "vnstat":' cfg/vnstat.conf || die "Failed to set DaemonUser!"
	sed -i 's:^DaemonGroup.*:DaemonGroup "vnstat":' cfg/vnstat.conf || die "Failed to set DaemonGroup!"
	sed -i 's:^MaxBWethnone.*:# &:' cfg/vnstat.conf || die "Failed to comment out example!"
	sed -i 's:vnstat[.]log:vnstatd.log:' cfg/vnstat.conf || die "Failed to adjust LogFile name!"
	sed -i 's:^PidFile.*:PidFile "/run/vnstat/vnstatd.pid":' cfg/vnstat.conf || die "Failed to adjust PidFile directive!"
}

src_compile() {
	emake CFLAGS="${CFLAGS}" $(usex gd all '')
}

src_install() {
	use gd && dobin src/vnstati
	dobin src/vnstat src/vnstatd

	exeinto /usr/share/${PN}
	newexe "${FILESDIR}"/vnstat.cron vnstat.cron

	insinto /etc
	doins cfg/vnstat.conf
	fowners root:vnstat /etc/vnstat.conf

	newconfd "${FILESDIR}"/vnstatd.confd vnstatd
	newinitd "${FILESDIR}"/vnstatd.initd vnstatd
	keepdir /var/lib/vnstat

	use gd && doman man/vnstati.1
	doman man/vnstat.1 man/vnstatd.1
	newdoc INSTALL README.setup
	dodoc CHANGES README UPGRADE FAQ examples/vnstat.cgi
}
pkg_postinst() {
	# Workaround feature/bug #141619
	chown -R vnstat:vnstat "${EROOT}"var/lib/vnstat
	chown vnstat:vnstat "${EROOT}"var/run/vnstatd
	ewarn "vnStat db files owning user and group has been changed to \"vnstat\"."

	elog
	elog "Repeat the following command for every interface you"
	elog "wish to monitor (replace eth0):"
	elog "   vnstat -u -i eth0"
	elog "and set correct permissions after that, e.g."
	elog "   chown -R vnstat:vnstat /var/lib/vnstat"
	elog
	elog "It is highly recommended to use the included vnstatd to update your"
	elog "vnStat databases."
	elog
	elog "If you want to use the old cron way to update your vnStat databases,"
	elog "you have to install the cronjob manually:"
	elog ""
	elog "   cp /usr/share/${PN}/vnstat.cron /etc/cron.hourly/vnstat"
	elog ""
	elog "Note: if an interface transfers more than ~4GB in"
	elog "the time between cron runs, you may miss traffic."
	elog "That's why using vnstatd instead of the cronjob is"
	elog "the recommended way to update your vnStat databases."
}
