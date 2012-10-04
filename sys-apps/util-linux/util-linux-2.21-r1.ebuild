# Distributed under the terms of the GNU General Public License v2

EAPI="3"

EGIT_REPO_URI="git://git.kernel.org/pub/scm/utils/util-linux/util-linux.git"
inherit eutils toolchain-funcs libtool flag-o-matic
[[ ${PV} == "9999" ]] && inherit git-2 autotools

MY_PV=${PV/_/-}
MY_P=${PN}-${MY_PV}
S=${WORKDIR}/${MY_P}

DESCRIPTION="Various useful Linux utilities"
HOMEPAGE="http://www.kernel.org/pub/linux/utils/util-linux/"
if [[ ${PV} == "9999" ]] ; then
	SRC_URI=""
	#KEYWORDS=""
else
	SRC_URI="mirror://kernel/linux/utils/util-linux/v${PV:0:4}/${MY_P}.tar.xz
		loop-aes? ( http://loop-aes.sourceforge.net/updates/util-linux-2.21-20120228.diff.bz2 )"
	KEYWORDS="*"
fi

LICENSE="GPL-2 GPL-3 LGPL-2.1 BSD-4 MIT public-domain"
SLOT="0"
IUSE="+cramfs crypt ddate loop-aes ncurses nls old-linux perl selinux slang static-libs uclibc unicode"

RDEPEND="!sys-process/schedutils
	!sys-apps/setarch
	!<sys-apps/sysvinit-2.88-r3
	!<sys-libs/e2fsprogs-libs-1.41.8
	!<sys-fs/e2fsprogs-1.41.8
	cramfs? ( sys-libs/zlib )
	ncurses? ( >=sys-libs/ncurses-5.2-r2 )
	perl? ( dev-lang/perl )
	selinux? ( sys-libs/libselinux )
	slang? ( sys-libs/slang )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )
	virtual/os-headers"

src_prepare() {
	if [[ ${PV} == "9999" ]] ; then
		po/update-potfiles
		autopoint --force
		eautoreconf
	else
		use loop-aes && epatch "${WORKDIR}"/util-linux-*.diff
	fi
	use uclibc && sed -i -e s/versionsort/alphasort/g -e s/strverscmp.h/dirent.h/g mount/lomount.c
	elibtoolize
}

lfs_fallocate_test() {
	# Make sure we can use fallocate with LFS #300307
	cat <<-EOF > "${T}"/fallocate.c
	#define _GNU_SOURCE
	#include <fcntl.h>
	main() { return fallocate(0, 0, 0, 0); }
	EOF
	append-lfs-flags
	$(tc-getCC) ${CFLAGS} ${CPPFLAGS} ${LDFLAGS} "${T}"/fallocate.c -o /dev/null >/dev/null 2>&1 \
		|| export ac_cv_func_fallocate=no
	rm -f "${T}"/fallocate.c
}

src_configure() {
	lfs_fallocate_test
	econf \
		--enable-fs-paths-extra=/usr/sbin \
		$(use_enable nls) \
		--enable-agetty \
		$(use_enable cramfs) \
		$(use_enable ddate) \
		$(use_enable old-linux elvtune) \
		--with-ncurses=$(usex ncurses $(usex unicode auto yes) no) \
		--disable-kill \
		--disable-last \
		--disable-mesg \
		--enable-partx \
		--enable-raw \
		--enable-rename \
		--disable-reset \
		--disable-login-utils \
		--enable-schedutils \
		--disable-wall \
		--enable-write \
		$(use_with selinux) \
		$(use_with slang) \
		$(use_enable static-libs static) \
		$(tc-has-tls || echo --disable-tls)
}

src_install() {
	emake install DESTDIR="${D}" || die
	dodoc AUTHORS NEWS README* Documentation/{TODO,*.txt}

	if ! use perl ; then #284093
		rm "${ED}"/usr/bin/chkdupexe || die
		rm "${ED}"/usr/share/man/man1/chkdupexe.1 || die
	fi

	# need the libs in /
	gen_usr_ldscript -a blkid mount uuid
	# e2fsprogs-libs didnt install .la files, and .pc work fine
	find "${ED}" -name '*.la' -delete

	if use crypt ; then
		newinitd "${FILESDIR}"/crypto-loop.initd crypto-loop || die
		newconfd "${FILESDIR}"/crypto-loop.confd crypto-loop || die
	fi
}
