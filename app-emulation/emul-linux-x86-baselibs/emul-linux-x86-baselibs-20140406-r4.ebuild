# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit emul-linux-x86

LICENSE="Artistic GPL-1 GPL-2 GPL-3 BSD BSD-2 BZIP2 AFL-2.1 LGPL-2.1 BSD-4 MIT
	public-domain LGPL-3 LGPL-2 GPL-2-with-exceptions MPL-1.1 OPENLDAP
	Sleepycat UoI-NCSA ZLIB openafs-krb5-a HPND ISC RSA IJG libmng libtiff
	openssl tcp_wrappers_license"

KEYWORDS="-* amd64"
IUSE="abi_x86_32"

SRC_URI="${SRC_URI} http://dev.gentoo.org/~pacho/emul/openssl-1.0.1g.tbz2"

DEPEND=""
RDEPEND="!<app-emulation/emul-linux-x86-medialibs-10.2
	!abi_x86_32? (
		!>=app-arch/xz-utils-5.0.5-r1[abi_x86_32(-)]
	)
	abi_x86_32? (
		>=sys-libs/zlib-1.2.8-r1[abi_x86_32(-)]
		>=app-arch/bzip2-1.0.6-r4[abi_x86_32(-)]
		>=media-libs/libpng-1.6.10:0[abi_x86_32(-)]
		>=dev-libs/udis86-1.7-r2[abi_x86_32(-)]
		>=virtual/libffi-3.0.13-r1[abi_x86_32(-)]
		>=sys-devel/llvm-3.3-r3[abi_x86_32(-)]
		>=media-libs/libpng-1.2.51:1.2[abi_x86_32(-)]
		>=virtual/jpeg-62:62[abi_x86_32(-)]
		>=sys-libs/libraw1394-2.1.0-r1[abi_x86_32(-)]
		>=sys-libs/libavc1394-0.5.4-r1[abi_x86_32(-)]
		>=dev-libs/expat-2.1.0-r3[abi_x86_32(-)]
		>=virtual/libusb-0-r1:0[abi_x86_32(-)]
		>=virtual/libusb-1-r1:1[abi_x86_32(-)]
		>=virtual/libudev-208[abi_x86_32(-)]
		>=media-libs/tiff-4.0.3-r6:0[abi_x86_32(-)]
		>=sys-apps/attr-2.4.47-r1[abi_x86_32(-)]
		>=dev-libs/glib-2.34.3:2[abi_x86_32(-)]
		>=media-libs/lcms-2.5-r1:2[abi_x86_32(-)]
		>=app-text/libpaper-1.1.24-r2[abi_x86_32(-)]
		>=media-libs/tiff-3.9.7-r1:3[abi_x86_32(-)]
		|| (
			>=dev-libs/elfutils-0.155-r1[abi_x86_32(-)]
			>=dev-libs/libelf-0.8.13-r2[abi_x86_32(-)]
		)
		>=sys-libs/e2fsprogs-libs-1.42.9[abi_x86_32(-)]
		>=sys-libs/ncurses-5.9-r3[abi_x86_32(-)]
		>=sys-libs/gpm-1.20.7-r2[abi_x86_32(-)]
		>=dev-libs/gmp-5.1.3-r1[abi_x86_32(-)]
		>=dev-libs/libpcre-8.33-r1[abi_x86_32(-)]
		>=sys-apps/dbus-1.6.18-r1[abi_x86_32(-)]
		>=sys-apps/tcp-wrappers-7.6.22-r1[abi_x86_32(-)]
		>=sys-libs/gdbm-1.10-r1[abi_x86_32(-)]
		>=dev-libs/json-c-0.11-r1[abi_x86_32(-)]
		>=dev-libs/libxml2-2.9.1-r4[abi_x86_32(-)]
		>=dev-libs/dbus-glib-0.100.2-r1[abi_x86_32(-)]
		>=sys-libs/readline-6.2_p5-r1:0[abi_x86_32(-)]
		>=sys-devel/gettext-0.18.3.2[abi_x86_32(-)]
		>=dev-libs/libgpg-error-1.12-r1[abi_x86_32(-)]
		>=dev-db/sqlite-3.8.3:3[abi_x86_32(-)]
		>=dev-libs/nettle-2.7.1-r1[abi_x86_32(-)]
		>=dev-libs/libtasn1-3.4-r1[abi_x86_32(-)]
		>=dev-libs/libgcrypt-1.5.3-r100:11[abi_x86_32(-)]
		>=dev-libs/libgcrypt-1.6.1-r1:0[abi_x86_32(-)]
		>=dev-libs/lzo-2.06-r1[abi_x86_32(-)]
		>=dev-libs/libxslt-1.1.28-r2[abi_x86_32(-)]
		>=sys-apps/file-5.18-r1[abi_x86_32(-)]
		>=app-arch/xz-utils-5.0.5-r1[abi_x86_32(-)]
		>=media-libs/giflib-4.2.3-r1[abi_x86_32(-)]
		>=sys-libs/slang-2.2.4-r1[abi_x86_32(-)]
		>=sys-apps/acl-2.2.52-r1[abi_x86_32(-)]
		>=sys-apps/util-linux-2.24.1-r3[abi_x86_32(-)]
		|| (
			>=dev-libs/libltdl-2.4.3:0[abi_x86_32(-)]
			>=sys-devel/libtool-2.4.2-r1[abi_x86_32(-)]
		)
		>=virtual/acl-0-r2[abi_x86_32(-)]
		>=dev-libs/openssl-1.0.1h-r2[abi_x86_32(-)]
	)
	>=sys-libs/glibc-2.16" # bug 340613

PYTHON_UPDATER_IGNORE="1"

src_prepare() {
	export ALLOWED="(${S}/lib32/security/pam_filter/upperLOWER|${S}/etc/env.d|${S}/lib32/security/pam_ldap.so)"
	emul-linux-x86_src_prepare
	rm -rf "${S}/etc/env.d/binutils/" \
			"${S}/usr/i686-pc-linux-gnu/lib" \
			"${S}/usr/lib32/engines/" \
			"${S}/usr/lib32/openldap/" || die

	ln -s ../share/terminfo "${S}/usr/lib32/terminfo" || die

	# Remove migrated stuff.
	use abi_x86_32 && rm -f $(sed "${FILESDIR}/remove-native-${PVR}" -e '/^#/d')
}

src_install() {
	emul-linux-x86_src_install
	rm -rf "${ED}"/usr/include # needed for openssl tbz2
}
