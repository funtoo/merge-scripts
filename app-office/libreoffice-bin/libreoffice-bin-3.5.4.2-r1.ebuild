# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-office/libreoffice-bin/libreoffice-bin-3.5.4.2-r1.ebuild,v 1.5 2012/06/08 11:45:26 phajdan.jr Exp $

EAPI=4

KDE_REQUIRED="optional"
CMAKE_REQUIRED="never"

BASE_AMD64_URI="mirror://gentoo/amd64-bin-"
BASE_X86_URI="mirror://gentoo/x86-bin-"

inherit kde4-base java-pkg-opt-2 pax-utils prefix

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

IUSE="+cups debug gnome java kde"
LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="-* amd64 x86"

BIN_COMMON_DEPEND="
	=app-text/libexttextcat-3.2*
	=dev-cpp/libcmis-0.1*
	=dev-libs/icu-49*
	>=sys-libs/glibc-2.14.1-r3
"

NSS_DEPEND="
	>=dev-libs/nspr-4.8.8
	>=dev-libs/nss-3.12.9
"

COMMON_DEPEND="
	${BIN_COMMON_DEPEND}
	app-arch/zip
	app-arch/unzip
	>=app-text/hunspell-1.3.2-r3
	app-text/mythes
	>=app-text/libexttextcat-3.2
	app-text/libwpd:0.9[tools]
	app-text/libwpg:0.2
	>=app-text/libwps-0.2.2
	dev-cpp/libcmis
	dev-db/unixODBC
	dev-libs/expat
	>=dev-libs/glib-2.28
	>=dev-libs/hyphen-2.7.1
	>=dev-libs/icu-49
	>=dev-lang/perl-5.0
	>=dev-libs/openssl-1.0.0d
	>=dev-libs/redland-1.0.14[ssl]
	>=media-libs/fontconfig-2.8.0
	media-libs/freetype:2
	>=media-libs/libpng-1.4
	media-libs/libvisio
	>=net-misc/curl-7.21.4
	sci-mathematics/lpsolve
	>=sys-libs/db-4.8
	virtual/jpeg
	>=x11-libs/cairo-1.10.0[X]
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libXrender
	>=dev-libs/dbus-glib-0.92
	gnome? ( gnome-extra/evolution-data-server )
	gnome? (
		gnome-base/gconf:2
		gnome-base/orbit
	)
	>=x11-libs/gtk+-2.24:2
	media-gfx/graphite2
	>=media-libs/gstreamer-0.10
	>=media-libs/gst-plugins-base-0.10
	java? (
		>=dev-java/bsh-2.0_beta4
		dev-java/lucene:2.9
		dev-java/lucene-analyzers:2.3
	)
	net-libs/neon
	${NSS_DEPEND}
"

RDEPEND="${COMMON_DEPEND}
	!app-office/libreoffice
	!app-office/openoffice-bin
	!app-office/openoffice
	media-fonts/libertine-ttf
	media-fonts/liberation-fonts
	media-fonts/urw-fonts
	cups? ( net-print/cups )
	java? ( >=virtual/jre-1.6 )
"

PDEPEND="
	>=app-office/libreoffice-l10n-3.5.0
"

# after all it's a binary package
DEPEND=""

# only one flavor at a time
REQUIRED_USE="kde? ( !gnome ) gnome? ( !kde )"

RESTRICT="test strip"

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

	use cups || \
		ewarn 'You will need net-print/cups to be able to print and export to PDF with libreoffice.'

	use java || \
		ewarn 'If you plan to use lbase aplication you should enable java or you will get various crashes.'
}

pkg_postrm() {
	kde4-base_pkg_postrm
}
