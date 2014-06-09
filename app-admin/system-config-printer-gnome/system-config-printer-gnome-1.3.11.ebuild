# Distributed under the terms of the GNU General Public License v2

EAPI="3"

PYTHON_DEPEND="2"
PYTHON_USE_WITH="xml"
WANT_AUTOMAKE="1.11"
inherit eutils python autotools

MY_P="${PN%-gnome}-${PV}"

DESCRIPTION="GNOME frontend for a Red Hat's printer administration tool"
HOMEPAGE="http://cyberelk.net/tim/software/system-config-printer/"
SRC_URI="http://cyberelk.net/tim/data/system-config-printer/1.3/${MY_P}.tar.xz"

LICENSE="GPL-2"
KEYWORDS="*"
SLOT="0"
IUSE="gnome-keyring"

# Needs cups running, bug 284005
RESTRICT="test"

RDEPEND="
	~app-admin/system-config-printer-common-${PV}
	dev-python/notify-python
	>=dev-python/pycups-1.9.60
	>=dev-python/pygtk-2.4
	gnome-keyring? ( dev-python/gnome-keyring-python )
"
DEPEND="${RDEPEND}
	app-text/docbook-xml-dtd:4.1.2
	>=app-text/xmlto-0.0.22
	dev-util/desktop-file-utils
	dev-util/intltool
	virtual/pkgconfig
	sys-devel/gettext
"

APP_LINGUAS="ar as bg bn_IN bn br bs ca cs cy da de el en_GB es et fa fi fr gu
he hi hr hu hy id is it ja ka kn ko lo lv mai mk ml mr ms nb nl nn or pa pl
pt_BR pt ro ru si sk sl sr@latin sr sv ta te th tr uk vi zh_CN zh_TW"
for X in ${APP_LINGUAS}; do
	IUSE="${IUSE} linguas_${X}"
done

S="${WORKDIR}/${MY_P}"

# Bug 471472, http://bugs.funtoo.org/browse/FL-1118
MAKEOPTS+=" -j1"



pkg_setup() {
	python_set_active_version 2
}

src_prepare() {
	epatch "${FILESDIR}/${PN}-1.3.11-split.patch"
	eautoreconf
}

src_configure() {
	local myconf

	# Disable installation of translations when LINGUAS not chosen
	if [[ -z "${LINGUAS}" ]]; then
		myconf="${myconf} --disable-nls"
	else
		myconf="${myconf} --enable-nls"
	fi

	econf \
		--with-desktop-vendor=Gentoo \
		--without-udev-rules \
		${myconf}
}

src_install() {
	dodoc AUTHORS ChangeLog README || die "dodoc failed"

	emake DESTDIR="${ED}" install || die "emake install failed"

	python_convert_shebangs -q -r $(python_get_version) "${ED}"
}

pkg_postrm() {
	python_mod_cleanup /usr/share/system-config-printer
}
