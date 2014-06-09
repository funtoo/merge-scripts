# Distributed under the terms of the GNU General Public License v2

EAPI="2" #356089

LIBTOOLIZE="true" #225559
WANT_LIBTOOL="none"
inherit eutils autotools multilib unpacker

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://git.savannah.gnu.org/${PN}.git
		http://git.savannah.gnu.org/r/${PN}.git"
	inherit git-2
else
	SRC_URI="mirror://gnu/${PN}/${P}.tar.xz"
	KEYWORDS="*"
fi

DESCRIPTION="A shared library tool for developers"
HOMEPAGE="http://www.gnu.org/software/libtool/"

LICENSE="GPL-2"
SLOT="2"
IUSE="static-libs test vanilla"

RDEPEND="sys-devel/gnuconfig
	!<sys-devel/autoconf-2.62:2.5
	!<sys-devel/automake-1.11.1:1.11
	!=sys-devel/libtool-2*:1.5"

DEPEND="${RDEPEND}
	test? ( !<sys-devel/binutils-2.20 )
	app-arch/xz-utils
	>=sys-devel/gcc-4.6.2"

[[ ${PV} == "9999" ]] && DEPEND+=" sys-apps/help2man"

pkg_setup() {
	# avoid the sed ebuild-helper if it was accidentally installed.
	if [ "$(which sed)" != "/bin/sed" ]
	then
		export PATH="/bin:$PATH"
	fi
}
src_unpack() {
	if [[ ${PV} == "9999" ]] ; then
		git-2_src_unpack
		cd "${S}"
		./bootstrap || die
	else
		unpacker_src_unpack
	fi
}

src_prepare() {
	use vanilla && return 0

	cd libltdl/m4
	epatch "${FILESDIR}"/1.5.20/${PN}-1.5.20-use-linux-version-in-fbsd.patch #109105
	cd ..
	AT_NOELIBTOOLIZE=yes eautoreconf
	cd ..
	AT_NOELIBTOOLIZE=yes eautoreconf
	epunt_cxx
}

src_configure() {
	# the libtool script uses bash code in it and at configure time, tries
	# to find a bash shell.  if /bin/sh is bash, it uses that.  this can
	# cause problems for people who switch /bin/sh on the fly to other
	# shells, so just force libtool to use /bin/bash all the time.
	export CONFIG_SHELL=/bin/bash

	econf $(use_enable static-libs static)
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog* NEWS README THANKS TODO doc/PLATFORMS

	# While the libltdl.la file is not used directly, the m4 ltdl logic
	# keys off of its existence when searching for ltdl support. #293921
	#use static-libs || find "${D}" -name libltdl.la -delete

	# Building libtool with --disable-static will cause the installed
	# helper to not build static objects by default.  This is undesirable
	# for crappy packages that utilize the system libtool, so undo that.
	dosed '1,/^build_old_libs=/{/^build_old_libs=/{s:=.*:=yes:}}' /usr/bin/libtool || die

	local x
	for x in $(find "${D}" -name config.guess -o -name config.sub) ; do
		ln -sf /usr/share/gnuconfig/${x##*/} "${x}" || die
	done
}

pkg_preinst() {
	preserve_old_lib /usr/$(get_libdir)/libltdl.so.3
}

pkg_postinst() {
	preserve_old_lib_notify /usr/$(get_libdir)/libltdl.so.3
}
