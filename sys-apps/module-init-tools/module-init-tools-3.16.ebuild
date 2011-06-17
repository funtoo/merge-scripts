# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/module-init-tools/module-init-tools-3.11.1.ebuild,v 1.4 2010/02/17 07:21:45 vapier Exp $

EAPI="2"

inherit eutils flag-o-matic

DESCRIPTION="tools for managing linux kernel modules"
HOMEPAGE="http://kerneltools.org/"
SRC_URI="mirror://kernel/linux/utils/kernel/module-init-tools/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh
~sparc ~x86"
IUSE="static"

DEPEND="sys-libs/zlib
	>=sys-apps/baselayout-2.0.1
	!sys-apps/modutils"

src_unpack() {
	unpack ${A}
	cd "${S}"
	rm -rf tests/build # punt precompiled objects
}

src_configure() {
	use static && append-ldflags -static
	econf \
		--prefix=/ \
		--enable-zlib \
		--enable-zlib-dynamic \
		--disable-static-utils
}

src_compile() {
	# don't regen man-pages:
	emake MAN5="" MAN8="" || die
}

src_test() {
	./tests/runtests -v || die
}

src_install() {
	# don't regen man-pages:
	emake install DESTDIR="${D}" MAN5="" MAN8="" || die
	dodoc AUTHORS ChangeLog NEWS README TODO

	into /
	newsbin "${FILESDIR}"/update-modules-3.5.sh update-modules || die
	doman "${FILESDIR}"/update-modules.8 || die

	# lsmod should be in /sbin, despite what upstream thinks. lsmod(8) is the
	# man page; it is a system tool like ifconfig or ip.
	mv ${D}/bin/lsmod ${D}/sbin/

	cat <<-EOF > "${T}"/usb-load-ehci-first.conf
	install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe --ignore-install ohci_hcd \$CMDLINE_OPTS
	install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe --ignore-install uhci_hcd \$CMDLINE_OPTS
	EOF

	insinto /etc/modprobe.d
	doins "${T}"/usb-load-ehci-first.conf || die #260139
}

pkg_postinst() {
	# cheat to keep users happy
	if grep -qs modules-update "${ROOT}"/etc/init.d/modules ; then
		sed -i 's:modules-update:update-modules:' "${ROOT}"/etc/init.d/modules
	fi

	# For files that were upgraded but not renamed via their ebuild to
	# have a proper .conf extension, rename them so etc-update tools can
	# take care of things. #274942
	local i f cfg
	eshopts_push -s nullglob
	for f in "${ROOT}"etc/modprobe.d/* ; do
		# The .conf files need no upgrading unless a non-.conf exists,
		# so skip this until later ...
		[[ ${f} == *.conf ]] && continue
		# If a .conf doesn't exist, then a package needs updating, or
		# the user created it, or it's orphaned.  Either way, we don't
		# really know, so leave it alone.
		[[ ! -f ${f}.conf ]] && continue

		i=0
		while :; do
			cfg=$(printf "%s/._cfg%04d_%s.conf" "${f%/*}" ${i} "${f##*/}")
			[[ ! -e ${cfg} ]] && break
			((i++))
		done
		elog "Updating ${f}; please run 'etc-update'"
		mv "${f}.conf" "${cfg}"
		mv "${f}" "${f}.conf"
	done
	# Whine about any non-.conf files that are left
	for f in "${ROOT}"etc/modprobe.d/* ; do
		[[ ${f} == *.conf ]] && continue
		ewarn "The '${f}' file needs to be upgraded to end with a '.conf'."
		ewarn "Either upgrade the package that owns it, or manually rename it."
	done
	eshopts_pop
}
