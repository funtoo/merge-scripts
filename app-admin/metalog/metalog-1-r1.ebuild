# Distributed under the terms of the GNU General Public License v2

EAPI="3"

inherit eutils

DESCRIPTION="A highly configurable replacement for syslogd/klogd"
HOMEPAGE="http://metalog.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.lzma"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE="unicode"

RDEPEND=">=dev-libs/libpcre-3.4"
DEPEND="${RDEPEND}
	|| ( app-arch/xz-utils app-arch/lzma-utils )"
PROVIDE="virtual/logger"

src_configure() {
	econf $(use_with unicode)
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"

	# Replace dist config with funtoo's one.
	rm -f "${D}/etc/metalog.conf"
	install "${FILESDIR}/metalog.conf" "${D}/etc/metalog.conf" -m 0600 -o root -g root

	dodoc AUTHORS ChangeLog README NEWS "${FILESDIR}/metalog.conf.dist"

	dosbin "${FILESDIR}/consolelog.sh" || die
	dosbin "${FILESDIR}/metalog-postrotate-compress.sh" || die

	newinitd "${FILESDIR}"/metalog.initd metalog
	newconfd "${FILESDIR}"/metalog.confd metalog
}
