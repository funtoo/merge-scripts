# Distributed under the terms of the GNU General Public License v2

EAPI="2"

inherit eutils

MY_P=${P/_/}
DESCRIPTION="Lightweight NTP server ported from OpenBSD"
HOMEPAGE="http://www.openntpd.org/"
SRC_URI="mirror://openbsd/OpenNTPD/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 mips ppc ppc64 s390 sh sparc x86 x86-fbsd"
IUSE="ssl selinux"

RDEPEND="ssl? ( dev-libs/openssl ) selinux? ( sec-policy/selinux-ntp ) !<=net-misc/ntp-4.2.0-r2"
DEPEND="${RDEPEND}"

S=${WORKDIR}/${MY_P}

pkg_preinst() {
	enewgroup ntp 123
	enewuser ntp 123 -1 /var/lib/openntpd/chroot ntp

	#make sure user has correct HOME
	usermod -d /var/lib/openntpd/chroot ntp

	if has_version net-misc/ntp && ! built_with_use net-misc/ntp openntpd ; then
		die "you need to emerge ntp with USE=openntpd"
	fi

	install -d $ROOT/var/lib/openntpd/chroot || die "chroot dir fail"
	chmod -R 0700 $ROOT/var/lib/openntpd || die "chmod fail"
	chown -R root:root $ROOT/var/lib/openntpd || die "chown fail"
}

src_prepare() {
	sed -i '/NTPD_USER/s:_ntp:ntp:' ntpd.h || die
	epatch "${FILESDIR}"/openntpd-3.9p1_reconnect_on_sendto_EINVAL.diff
}

src_configure() {
	econf \
		--disable-strip \
		$(use_with !ssl builtin-arc4random) || die
}

src_compile() {
	emake || die "emake failed"
}

src_install() {
	make install DESTDIR="${D}" || die
	dodoc ChangeLog CREDITS README
	newinitd "${FILESDIR}"/${PF}/ntpd ntpd || die "newinitd fail"
	newconfd "${FILESDIR}"/${PF}/ntpd.conf.d ntpd || die "newconfd fail"
}
