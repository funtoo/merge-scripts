# Distributed under the terms of the GNU General Public License v2

EAPI=2

inherit eutils versionator

MY_PV=$(get_version_component_range 1-2)
MY_BUILD=$(get_version_component_range 3)
MY_P="oss-v${MY_PV}-build${MY_BUILD}-src-gpl"

DESCRIPTION="Open Sound System - portable, mixing-capable, high quality sound system for Unix."
HOMEPAGE="http://developer.opensound.com/"
SRC_URI="http://www.4front-tech.com/developer/sources/stable/gpl/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"

IUSE="gtk salsa midi"

RESTRICT="mirror"

DEPEND="sys-apps/gawk 
	gtk? ( >=x11-libs/gtk+-2 ) 
	>=sys-kernel/linux-headers-2.6.11
	!media-sound/oss-devel"

RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	mkdir "${WORKDIR}/build"

	einfo "Replacing init script with gentoo friendly one ..."
	cp "${FILESDIR}/oss" "${S}/setup/Linux/oss/etc/S89oss"

	sed -i -e 's/-Werror//' phpmake/Makefile.php setup/Linux/oss/build/install.sh setup/srcconf_linux.inc

	#epatch "${FILESDIR}/usb.patch"
}

src_configure() {
	local myconf="$(use salsa && echo  || echo --enable-libsalsa=NO) \
		--config-midi=$(use midi && echo YES || echo NO)"

	cd "${WORKDIR}/build"

	# Configure has to be run from build dir with full path.
	"${S}"/configure \
		${myconf} || die "configure failed"
}

src_compile() {
	cd "${WORKDIR}/build"

	emake build || die 'emake failed'
}

src_install() {
	newinitd "${FILESDIR}/oss" oss
	cp -R "${WORKDIR}"/build/prototype/* "${D}"

	echo 'CONFIG_PROTECT="$CONFIG_PROTECT /usr/lib/oss/conf/"' > 99oss
	doenvd 99oss || die "doenvd failed"
}

pkg_postinst() {
	ewarn "In order to use OSSv4 you must run"
	ewarn "# /etc/init.d/oss start "
	ewarn "If you are upgrading from a previous build of OSSv4 you must run"
	ewarn "# /etc/init.d/oss restart "
	ewarn 'and may need to remove /lib/modules/$KERNEL_VERSION/kernel/oss/'
}
