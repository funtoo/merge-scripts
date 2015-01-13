# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils multilib

LIBFM="libfm-1.2.3"

DESCRIPTION="A library creating and utilizing caches to speed up freedesktop.org application menus"
HOMEPAGE="http://lxde.sourceforge.net/"
SRC_URI="mirror://sourceforge/lxde/${P}.tar.xz
	mirror://sourceforge/pcmanfm/${LIBFM}.tar.xz"

LICENSE="GPL-2"
# Subslot based on soname of libmenu-cache.so.
SLOT="0/3"
KEYWORDS="*"
IUSE=""

RDEPEND="dev-libs/glib:2"
DEPEND="${RDEPEND}
	sys-devel/gettext
	virtual/pkgconfig"
PDEPEND="x11-libs/libfm"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-segfault-fix.patch
}

src_configure() {
	pushd "${WORKDIR}/${LIBFM}" > /dev/null || die
	econf \
		--disable-static \
		--with-extra-only
	emake
	emake DESTDIR="${T}/libfm" install
	popd > /dev/null || die

	LIBFM_EXTRA_CFLAGS="-I${T}/libfm/usr/include" \
	LIBFM_EXTRA_LIBS="-L${T}/libfm/usr/$(get_libdir) -lfm-extra" \
	econf

	# Avoid setting rpath.
	sed -e "s/^hardcode_libdir_flag_spec=.*/hardcode_libdir_flag_spec=/" -i libtool || die
}
