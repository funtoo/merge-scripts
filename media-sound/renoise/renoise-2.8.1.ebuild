# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit eutils

DESCRIPTION="Complete DAW using a tracker-based approach"
HOMEPAGE="http://www.renoise.com/"

MY_ARCH=${ARCH/amd64/x86_64}
SRC_URI="rns_2_8_1_reg_${MY_ARCH}.tar.gz"
S="${WORKDIR}/rns_2_8_1_reg_${MY_ARCH}"

LICENSE="renoise-EULA"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="-icons"
RESTRICT="fetch strip"

DEPEND="
	icons? (
		x11-misc/xdg-utils
	)
"

RDEPEND="
	media-libs/alsa-lib
"

pkg_nofetch() {
	elog "Download ${A} from ${HOMEPAGE} and place it in ${DISTDIR}"
}

src_install() {
	mkdir -p ${D}/usr/share/renoise-${PV}
	cp -r Resources/* ${D}/usr/share/renoise-${PV}
	mkdir -p ${D}/usr/bin
	cp renoise ${D}/usr/bin/renoise-${PV}
	dosym /usr/bin/renoise-${PV} /usr/bin/renoise
	doman Installer/renoise.1.gz
	doman Installer/renoise-pattern-effects.5.gz

	if use icons ; then
		xdg-mime install --novendor Installer/renoise.xml
		doicon -s 48 -c apps Installer/renoise.png
		doicon -s 48 -c mimetypes Installer/renoise.png application-x-renoise-module
		doicon -s 48 -c mimetypes Installer/renoise.png application-x-renoise-rns-module
		domenu Installer/renoise.desktop
	fi
}
