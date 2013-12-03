# Distributed under the terms of the GNU General Public License v2

EAPI=5

KDE_REQUIRED="optional"
CMAKE_REQUIRED="never"

BASE_AMD64_URI="http://ftp.osuosl.org/pub/funtoo/distfiles/amd64-bin-"
BASE_X86_URI="http://ftp.osuosl.org/pub/funtoo/distfiles/x86-bin-"

PYTHON_COMPAT=( python2_7 python3_3 )
PYTHON_REQ_USE="threads,xml"

inherit kde4-base java-pkg-opt-2 python-single-r1 pax-utils prefix versionator

DESCRIPTION="LibreOffice, a full office productivity suite. Binary package."
HOMEPAGE="http://www.libreoffice.org"
SRC_URI_AMD64="
	kde? (
		!java? ( ${BASE_AMD64_URI}${PN/-bin}-kde-${PVR}.tar.xz )
		java? ( ${BASE_AMD64_URI}${PN/-bin}-kde-java-${PVR}.tar.xz )
	)
	gnome? (
		!java? ( ${BASE_AMD64_URI}${PN/-bin}-gnome-${PVR}.tar.xz )
		java? ( ${BASE_AMD64_URI}${PN/-bin}-gnome-java-${PVR}.tar.xz )
	)
	!kde? ( !gnome? (
		!java? ( ${BASE_AMD64_URI}${PN/-bin}-base-${PVR}.tar.xz )
		java? ( ${BASE_AMD64_URI}${PN/-bin}-base-java-${PVR}.tar.xz )
	) )
"
SRC_URI_X86="
	kde? (
		!java? ( ${BASE_X86_URI}${PN/-bin}-kde-${PVR}.tar.xz )
		java? ( ${BASE_X86_URI}${PN/-bin}-kde-java-${PVR}.tar.xz )
	)
	gnome? (
		!java? ( ${BASE_X86_URI}${PN/-bin}-gnome-${PVR}.tar.xz )
		java? ( ${BASE_X86_URI}${PN/-bin}-gnome-java-${PVR}.tar.xz )
	)
	!kde? ( !gnome? (
		!java? ( ${BASE_X86_URI}${PN/-bin}-base-${PVR}.tar.xz )
		java? ( ${BASE_X86_URI}${PN/-bin}-base-java-${PVR}.tar.xz )
	) )
"

SRC_URI="
	amd64? ( ${SRC_URI_AMD64} )
	x86? ( ${SRC_URI_X86} )
"

IUSE="debug gnome java kde"
LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"

BIN_COMMON_DEPEND="
	=app-text/libexttextcat-3.4*
	app-text/poppler:0/43
	dev-libs/boost:0/1.53.0
	dev-libs/icu:0/52
	=media-gfx/graphite2-1.2*
	=media-libs/harfbuzz-0.9.12
	=media-libs/libpng-1.5*
	>=sys-libs/glibc-2.15-r3
	kde? ( >=kde-base/kdelibs-4.10.5-r1:4 >=dev-qt/qtcore-4.8.4-r5:4 )
	|| ( <media-libs/libjpeg-turbo-1.3.0-r2 =media-libs/jpeg-8* )
"

# PLEASE place any restrictions that are specific to the binary builds
# into the BIN_COMMON_DEPEND block above. 
# All dependencies below this point should remain identical to those in 
# the source ebuilds.

COMMON_DEPEND="
	${BIN_COMMON_DEPEND}
	${PYTHON_DEPS}
	app-arch/zip
	app-arch/unzip
	>=app-text/hunspell-1.3.2-r3
	app-text/mythes
	>=app-text/libexttextcat-3.2
	app-text/liblangtag
	app-text/libmspub
	>=app-text/libmwaw-0.1.7
	app-text/libodfgen
	app-text/libwpd:0.9[tools]
	app-text/libwpg:0.2
	>=app-text/libwps-0.2.2
	>=app-text/poppler-0.16:=[xpdf-headers(+),cxx]
	>=dev-cpp/clucene-2.3.3.4-r2
	>=dev-cpp/libcmis-0.3.1:0.3
	dev-db/unixODBC
	>=dev-libs/boost-1.46:=
	dev-libs/expat
	>=dev-libs/hyphen-2.7.1
	>=dev-libs/icu-4.8.1.1:=
	>=dev-libs/liborcus-0.5.1:=
	>=dev-libs/nspr-4.8.8
	>=dev-libs/nss-3.12.9
	>=dev-lang/perl-5.0
	>=dev-libs/openssl-1.0.0d
	>=dev-libs/redland-1.0.16[ssl]
	media-gfx/graphite2
	>=media-libs/fontconfig-2.8.0
	media-libs/freetype:2
	>=media-libs/harfbuzz-0.9.10:=[icu(+)]
	media-libs/lcms:2
	>=media-libs/libpng-1.4
	>=media-libs/libcdr-0.0.5
	media-libs/libvisio
	>=net-misc/curl-7.21.4
	net-nds/openldap
	sci-mathematics/lpsolve
	virtual/jpeg
	>=x11-libs/cairo-1.10.0[X]
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libXrender
	net-print/cups
	>=dev-libs/dbus-glib-0.92
	gnome? ( gnome-extra/evolution-data-server )
	gnome? ( gnome-base/gconf:2 )
	x11-libs/gdk-pixbuf[X]
	>=x11-libs/gtk+-2.24:2
	media-libs/gstreamer:1.0
	media-libs/gst-plugins-base:1.0
	virtual/glu
	virtual/opengl
	net-libs/neon
"

RDEPEND="${COMMON_DEPEND}
	!app-office/libreoffice
	!<app-office/openoffice-bin-3.4.0-r1
	!app-office/openoffice
	media-fonts/libertine-ttf
	media-fonts/liberation-fonts
	media-fonts/urw-fonts
	java? ( >=virtual/jre-1.6 )
"

PDEPEND="
	=app-office/libreoffice-l10n-${PV}*
"

DEPEND=""

# only one flavor at a time
REQUIRED_USE="kde? ( !gnome ) gnome? ( !kde )"

RESTRICT="test strip mirror"

S="${WORKDIR}"

PYTHON_UPDATER_IGNORE="1"

pkg_pretend() {
	[[ $(gcc-major-version) -lt 4 ]] || \
			( [[ $(gcc-major-version) -eq 4 && $(gcc-minor-version) -le 4 ]] ) \
		&& die "Sorry, but gcc-4.4 and earlier won't work for libreoffice-bin package (see bug #387515)."
}

pkg_setup() {
	kde4-base_pkg_setup
}

src_unpack() {
	default
}

src_prepare() {
	cp "${FILESDIR}"/50-${PN} "${T}"
	eprefixify "${T}"/50-${PN}
}

src_configure() { :; }

src_compile() { :; }

src_install() {
	dodir /usr
	cp -aR "${S}"/usr/* "${ED}"/usr/

	# prevent revdep-rebuild from attempting to rebuild all the time
	insinto /etc/revdep-rebuild && doins "${T}/50-${PN}"
}

pkg_preinst() {
	# Cache updates - all handled by kde eclass for all environments
	kde4-base_pkg_preinst
}

pkg_postinst() {
	kde4-base_pkg_postinst

	pax-mark -m "${EPREFIX}"/usr/$(get_libdir)/libreoffice/program/soffice.bin
	pax-mark -m "${EPREFIX}"/usr/$(get_libdir)/libreoffice/program/unopkg.bin

	use java || \
		ewarn 'If you plan to use lbase application you should enable java or you will get various crashes.'
}

pkg_postrm() {
	kde4-base_pkg_postrm
}
