# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-nntp/tin/tin-1.9.4-r1.ebuild,v 1.1 2010/01/09 19:11:02 jer Exp $

EAPI="2"

inherit versionator eutils

DESCRIPTION="A threaded NNTP and spool based UseNet newsreader"
HOMEPAGE="http://www.tin.org/"
SRC_URI="ftp://ftp.tin.org/pub/news/clients/tin/v$(get_version_component_range 1-2)/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ia64 ~ppc ~sparc ~x86"
IUSE="cancel-locks crypt debug evil forgery idn ipv6 nls unicode socks5 +etiquette"

DEPEND="
	crypt? ( app-crypt/gnupg )
	idn? ( net-dns/libidn )
	nls? ( sys-devel/gettext )
	socks5? ( net-proxy/dante )
	unicode? ( dev-libs/icu )
	dev-libs/libpcre
	dev-libs/uulib
	sys-libs/ncurses[unicode?]
"

RDEPEND="${DEPEND}
	net-misc/urlview"

src_prepare() {
	# Do not strip
	sed -i src/Makefile.in -e '388s|-s ||g' || die "sed src/Makefile.in failed"
}

src_compile() {
	emake build || die "emake failed"
}

src_configure() {
	if use evil || use cancel-locks; then
		sed -i -e"s/# -DEVIL_INSIDE/-DEVIL_INSIDE/" src/Makefile.in
	fi

	if use forgery
	then
		sed -i -e"s/^CPPFLAGS.*/& -DFORGERY/" src/Makefile.in
	fi

	local screen="ncurses"
	use unicode && screen="ncursesw"

	use etiquette || myconf="${myconf} --disable-etiquette"

	econf \
		--with-pcre=/usr \
		--enable-nntp-only \
		--enable-prototypes \
		--disable-echo \
		--disable-mime-strict-charset \
		--with-coffee  \
		--with-screen=${screen} \
		--with-nntp-default-server="${TIN_DEFAULT_SERVER:-${NNTPSERVER:-news.gmane.org}}" \
		$(use_enable ipv6) \
		$(use_enable debug) \
		$(use_enable crypt pgp-gpg) \
		$(use_enable nls) \
		$(use_enable cancel-locks) \
		$(use_with socks5) \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	rm -f "${D}"/usr/share/man/man5/{mbox,mmdf}.5

	dodoc doc/{CHANGES{,.old},CREDITS,TODO,WHATSNEW,*.sample,*.txt} || die "dodoc failed"
	insinto /etc/tin
	doins doc/tin.defaults || die "doins failed"
}
