# Distributed under the terms of the GNU General Public License v2

EAPI=4

#BACKPORTS=4

if [[ ${PV} = *9999* ]]; then
	EGIT_REPO_URI="http://git.fedorahosted.org/git/virt-manager.git"
fi

PYTHON_DEPEND="2:2.5"

# Stop gnome2.eclass from doing stuff on USE=debug
GCONF_DEBUG="no"

inherit eutils gnome2 python

if [[ ${PV} = *9999* ]]; then
	inherit git-2 autotools
	SRC_URI=""
	KEYWORDS=""
	VIRTINSTDEP=">=app-emulation/virtinst-9999"
else
	SRC_URI="http://virt-manager.org/download/sources/${PN}/${P}.tar.gz
	${BACKPORTS:+mirror://gentoo/${P}-bp-${BACKPORTS}.tar.bz2
		http://dev.gentoo.org/~cardoe/distfiles/${P}-bp-${BACKPORTS}.tar.bz2}"
	KEYWORDS="amd64 x86"
	VIRTINSTDEP=">=app-emulation/virtinst-0.600.2"
fi

DESCRIPTION="A graphical tool for administering virtual machines (KVM/Xen)"
HOMEPAGE="http://virt-manager.org/"
LICENSE="GPL-2"
SLOT="0"
IUSE="gnome-keyring policykit sasl +spice +vnc"
RDEPEND=">=dev-python/pygtk-1.99.12
	>=app-emulation/libvirt-0.7.0[python,sasl?]
	>=dev-libs/libxml2-2.6.23[python]
	${VIRTINSTDEP}
	>=gnome-base/librsvg-2
	>=x11-libs/vte-0.12.2:0[python]
	>=dev-python/dbus-python-0.61
	>=dev-python/gconf-python-1.99.11
	dev-python/urlgrabber
	sys-apps/dbus[X]
	gnome-keyring? ( dev-python/gnome-keyring-python )
	policykit? ( sys-auth/polkit )
	spice? (
		>=net-misc/spice-gtk-0.6[python,sasl?]
		|| (
			<=net-misc/spice-gtk-0.14[python,sasl?,-gtk3]
			>=net-misc/spice-gtk-0.14-r1[python,sasl?]
		)
	)
	vnc? ( >=net-libs/gtk-vnc-0.3.8[python,sasl?] )"
#	tui? ( >=dev-python/new_syrup-0.1.2 )"
DEPEND="${RDEPEND}
	app-text/rarian
	dev-util/intltool"

pkg_setup() {
	G2CONF="--without-tui"
	python_set_active_version 2
	python_pkg_setup
}

src_prepare() {
	sed -e "s/python/python2/" -i src/virt-manager.in || \
		die "python2 update failed"

	[[ -n ${BACKPORTS} ]] && \
		EPATCH_FORCE=yes EPATCH_SUFFIX="patch" EPATCH_SOURCE="${S}/patches" \
			epatch

	if [[ ${PV} = *9999* ]]; then
		# virt-manager's autogen.sh touches this and eautoreconf fails
		# unless we do this
		touch config.rpath

		rm -rf config.status || die
		intltoolize --automake --copy --force || die
		perl -i -p -e 's,^DATADIRNAME.*$,DATADIRNAME = share,' po/Makefile.in.in || die
		perl -i -p -e 's,^GETTEXT_PACKAGE.*$,GETTEXT_PACKAGE = virt-manager,' \
			po/Makefile.in.in || die
		eautoreconf
	fi

	gnome2_src_prepare
}

pkg_postinst() {
	python_mod_optimize /usr/share/${PN}
	gnome2_pkg_postinst
}

pkg_postrm() {
	python_mod_cleanup /usr/share/${PN}
	gnome2_pkg_postrm
}
