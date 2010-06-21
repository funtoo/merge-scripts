# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-nntp/tin/tin-1.8.3.ebuild,v 1.8 2010/01/09 19:11:02 jer Exp $

EAPI="2"

inherit versionator eutils

DESCRIPTION="A threaded NNTP and spool based UseNet newsreader"
HOMEPAGE="http://www.tin.org/"
SRC_URI="ftp://ftp.tin.org/pub/news/clients/tin/v$(get_version_component_range 1-2)/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 arm ia64 ppc sparc x86"
IUSE="crypt debug idn ipv6 nls unicode"

DEPEND="dev-libs/libpcre
	dev-libs/uulib
	idn? ( net-dns/libidn )
	unicode? ( dev-libs/icu sys-libs/ncurses[unicode] )
	!unicode? ( sys-libs/ncurses )
	nls? ( sys-devel/gettext )
	crypt? ( app-crypt/gnupg )"
RDEPEND="${DEPEND}
	net-misc/urlview"

src_prepare() {
	epatch "${FILESDIR}"/1.8.2-various.patch
}

src_configure() {
	local screen="ncurses"

	use unicode && screen="ncursesw"

	econf \
		--with-pcre=/usr \
		--enable-nntp-only \
		--enable-prototypes \
		--disable-echo \
		--disable-mime-strict-charset \
		--with-coffee  \
		--enable-fascist-newsadmin \
		--with-screen=${screen} \
		--with-nntp-default-server="${TIN_DEFAULT_SERVER:-${NNTPSERVER:-news.gmane.org}}" \
		$(use_enable ipv6) \
		$(use_enable debug) \
		$(use_enable crypt pgp-gpg) \
		$(use_enable nls) \
		|| die "econf failed"
}

src_compile() {
	emake build || die "emake failed"
}

src_install() {
	make DESTDIR="${D}" install || die "make install failed"

	dodoc doc/{CHANGES{,.old},CREDITS,TODO,WHATSNEW,*.sample,*.txt} || die "dodoc failed"
	insinto /etc/tin
	doins doc/tin.defaults || die "doins failed"
}
