# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils flag-o-matic

DESCRIPTION="Scheme interpreter. Also The GNU extension language"
HOMEPAGE="http://www.gnu.org/software/guile/"
SRC_URI="mirror://gnu/guile/${P}.tar.gz"

LICENSE="LGPL-3+"
SLOT="0/2.0.11"
KEYWORDS="*"
IUSE="debug debug-malloc +deprecated emacs networking nls +regex static +threads"

RESTRICT="mirror"

RDEPEND="
	dev-libs/boehm-gc[threads?]
	dev-libs/gmp:0=
	dev-libs/libltdl:0=
	dev-libs/libunistring:0=
	virtual/libffi
	virtual/libiconv
	virtual/libintl

	emacs? ( virtual/emacs )"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_configure() {
	replace-flags -Os -O2
	econf \
		--disable-error-on-warning \
		--disable-rpath \
		--disable-static \
		--enable-posix \
		--with-modules \
		$(use_enable debug guile-debug) \
		$(use_enable debug-malloc) \
		$(use_enable deprecated) \
		$(use_enable networking) \
		$(use_enable nls) \
		$(use_enable regex) \
		$(use_enable static) \
		$(use_with threads)
}

src_install() {
	einstall

	dodoc AUTHORS COPYING COPYING.LESSER ChangeLog GUILE-VERSION HACKING LICENSE NEWS README THANKS || die

	# From Novell
	# 	https://bugzilla.novell.com/show_bug.cgi?id=874028#c0
	dodir /usr/share/gdb/auto-load/$(get_libdir)

	mv ${D}/usr/$(get_libdir)/libguile-*-gdb.scm ${D}/usr/share/gdb/auto-load/$(get_libdir)
}
