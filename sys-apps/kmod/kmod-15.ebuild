# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit autotools eutils libtool multilib toolchain-funcs versionator

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="git://git.kernel.org/pub/scm/utils/kernel/${PN}/${PN}.git"
	inherit git-2
else
	SRC_URI="mirror://kernel/linux/utils/kernel/kmod/${P}.tar.xz"
	KEYWORDS="*"
fi

DESCRIPTION="library and tools for managing linux kernel modules"
HOMEPAGE="http://git.kernel.org/?p=utils/kernel/kmod/kmod.git"

LICENSE="LGPL-2"
SLOT="0"
IUSE="debug doc lzma static-libs +tools zlib"

# Upstream does not support running the test suite with custom configure flags.
# I was also told that the test suite is intended for kmod developers.
# So we have to restrict it.
# See bug #408915.
RESTRICT="test"

RDEPEND="!sys-apps/module-init-tools
	!sys-apps/modutils
	lzma? ( >=app-arch/xz-utils-5.0.4-r1 )
	zlib? ( >=sys-libs/zlib-1.2.6 )" #427130
DEPEND="${RDEPEND}
	dev-libs/libxslt
	doc? ( dev-util/gtk-doc )
	lzma? ( virtual/pkgconfig )
	zlib? ( virtual/pkgconfig )"

pkg_setup() {
	version_is_at_least 4.6 $(gcc-version) || \
		die "At least sys-devel/gcc >= 4.6 is required to build ${CATEGORY}/${PN}." #481020
}

src_prepare() {
	if [ ! -e configure ]; then
		if use doc; then
			gtkdocize --copy --docdir libkmod/docs || die
		else
			touch libkmod/docs/gtk-doc.make
		fi
		eautoreconf
	else
		elibtoolize
	fi

	# Restore possibility of running --enable-static wrt #472608
	sed -i \
		-e '/--enable-static is not supported by kmod/s:as_fn_error:echo:' \
		configure || die
}

src_configure() {
	econf \
		--bindir=/sbin \
		--with-rootlibdir=/$(get_libdir) \
		--enable-shared \
		$(use_enable static-libs static) \
		$(use_enable tools) \
		$(use_enable debug) \
		$(use_enable doc gtk-doc) \
		$(use_with lzma xz) \
		$(use_with zlib)
}

src_install() {
	default
	prune_libtool_files

	if use tools; then
		local sbincmd
		for sbincmd in depmod insmod lsmod modinfo modprobe rmmod; do
			dosym /sbin/kmod /sbin/${sbincmd}
		done
	fi

	cat <<-EOF > "${T}"/usb-load-ehci-first.conf
	softdep uhci_hcd pre: ehci_hcd
	softdep ohci_hcd pre: ehci_hcd
	EOF

	insinto /lib/modprobe.d
	doins "${T}"/usb-load-ehci-first.conf #260139

}
