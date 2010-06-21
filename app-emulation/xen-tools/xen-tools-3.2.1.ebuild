# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/xen-tools/xen-tools-3.2.1.ebuild,v 1.3 2009/06/27 07:12:39 patrick Exp $

inherit flag-o-matic eutils multilib

DESCRIPTION="Xend daemon and tools"
HOMEPAGE="http://xen.org/"
SRC_URI="http://bits.xensource.com/oss-xen/release/${PV}/xen-${PV}.tar.gz"
S="${WORKDIR}/xen-${PV}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc debug screen custom-cflags pygrub hvm"

CDEPEND="dev-lang/python
	sys-libs/zlib
	hvm? ( media-libs/libsdl )"

DEPEND="${CDEPEND}
	sys-devel/gcc
	dev-lang/perl
	app-misc/pax-utils
	doc? (
		dev-tex/latex2html
		media-gfx/transfig
		media-gfx/graphviz
	)
	hvm? (
		x11-proto/xproto
		net-libs/libvncserver
		sys-devel/dev86
	)"

RDEPEND="${CDEPEND}
	sys-apps/iproute2
	net-misc/bridge-utils
	screen? (
		app-misc/screen
		app-admin/logrotate
	)
	|| ( sys-fs/udev sys-apps/hotplug )"

PYTHON_MODNAME="xen grub"

# hvmloader is used to bootstrap a fully virtualized kernel
# Approved by QA team in bug #144032
QA_WX_LOAD="usr/lib/xen/boot/hvmloader"

pkg_setup() {
	if ! use x86 && ! has x86 $(get_all_abis) && use hvm; then
		eerror "HVM (VT-x and AMD-v) cannot be built on this system. An x86 or"
		eerror "an amd64 multilib profile is required. Remove the hvm use flag"
		eerror "to build xen-tools on your current profile."
		die "USE=hvm is unsupported on this system."
	fi

	if [[ -z ${XEN_TARGET_ARCH} ]] ; then
		if use x86 && use amd64; then
			die "Confusion! Both x86 and amd64 are set in your use flags!"
		elif use x86; then
			export XEN_TARGET_ARCH="x86_32"
		elif use amd64 ; then
			export XEN_TARGET_ARCH="x86_64"
		else
			die "Unsupported architecture!"
		fi
	fi

	if use doc && ! built_with_use -o dev-tex/latex2html png gif; then
		# die early instead of later
		eerror "USE=doc requires latex2html with image support. Please add"
		eerror "'png' and/or 'gif' to your use flags and re-emerge latex2html"
		die "latex2html missing both png and gif flags"
	fi

	if use pygrub && ! built_with_use dev-lang/python ncurses; then
		eerror "USE=pygrub requires python to be built with ncurses support. Please add"
		eerror "'ncurses' to your use flags and re-emerge python"
		die "python is missing ncurses flags"
	fi
}

src_unpack() {
	unpack ${A}
	cd "${S}"

	# if the user *really* wants to use their own custom-cflags, let them
	if use custom-cflags; then
		einfo "User wants their own CFLAGS - removing defaults"
		# try and remove all the default custom-cflags
		find "${S}" -name Makefile -o -name Rules.mk -o -name Config.mk -exec sed \
			-e 's/CFLAGS\(.*\)=\(.*\)-O3\(.*\)/CFLAGS\1=\2\3/' \
			-e 's/CFLAGS\(.*\)=\(.*\)-march=i686\(.*\)/CFLAGS\1=\2\3/' \
			-e 's/CFLAGS\(.*\)=\(.*\)-fomit-frame-pointer\(.*\)/CFLAGS\1=\2\3/' \
			-e 's/CFLAGS\(.*\)=\(.*\)-g3*\s\(.*\)/CFLAGS\1=\2 \3/' \
			-e 's/CFLAGS\(.*\)=\(.*\)-O2\(.*\)/CFLAGS\1=\2\3/' \
			-i {} \;
	fi

	# Disable hvm support on systems that don't support x86_32 binaries.
	if ! use hvm; then
		chmod 644 tools/check/check_x11_devel
		sed -i -e '/^CONFIG_IOEMU := y$/d' "${S}"/config/*.mk
		sed -i -e '/SUBDIRS-$(CONFIG_X86) += firmware/d' "${S}"/tools/Makefile
	fi

	if ! use pygrub; then
		sed -i -e "/^SUBDIRS-y += pygrub$/d" "${S}"/tools/Makefile
	fi

	# Allow --as-needed LDFLAGS
	epatch "${FILESDIR}/${PN}-3.0.4_p1--as-needed.patch"

	# Fix network broadcast on bridged networks
	epatch "${FILESDIR}/${PN}-3.1.3-network-bridge-broadcast.patch"

	# Fix building small dumb utility called 'xen-detect' on hardened
	epatch "${FILESDIR}/${PN}-3.1.0-xen-detect-nopie-fix.patch"

	# Introduce a configure option to disable qemu documentation building, #192427
	epatch "${FILESDIR}/${PN}-3.2.1-qemu-nodocs.patch"
}

src_compile() {
	export VARTEXFONTS="${T}/fonts"
	local myopt myconf
	use debug && myopt="${myopt} debug=y"

	use custom-cflags || unset CFLAGS
	if test-flag-CC -fno-strict-overflow; then
		append-flags -fno-strict-overflow
	fi

	if use hvm; then
		myconf="${myconf} --disable-system --disable-user"
		(cd tools/ioemu && econf ${myconf}) || die "configure failured"
	fi

	emake -C tools ${myopt} || die "compile failed"

	if use doc; then
		sh ./docs/check_pkgs || die "package check failed"
		emake -C docs || die "compiling docs failed"
	fi

	emake -C docs man-pages || die "make man-pages failed"
}

src_install() {
	local myopt="XEN_PYTHON_NATIVE_INSTALL=1"

	make DESTDIR="${D}" -C tools ${myopt} install \
		|| die "install failed"

	# Remove RedHat-specific stuff
	rm -rf "${D}"/etc/sysconfig

	if use doc; then
		make DESTDIR="${D}" -C docs install || die "install docs failed"
		# Rename doc/xen to the Gentoo-style doc/xen-x.y
		mv "${D}"/usr/share/doc/{${PN},${PF}}
	fi

	doman docs/man?/*

	newinitd "${FILESDIR}"/xend.initd xend \
		|| die "Couldn't install xen.initd"
	newconfd "${FILESDIR}"/xendomains.confd xendomains \
		|| die "Couldn't install xendomains.confd"
	newinitd "${FILESDIR}"/xendomains.initd xendomains \
		|| die "Couldn't install xendomains.initd"

	if use screen; then
		cat "${FILESDIR}"/xendomains-screen.confd >> "${D}"/etc/conf.d/xendomains
		cp "${FILESDIR}"/xen-consoles.logrotate "${D}"/etc/xen/
		keepdir /var/log/xen-consoles
	fi

	# xend expects these to exist
	keepdir /var/run/xenstored /var/lib/xenstored /var/xen/dump /var/lib/xen /var/log/xen

	# for xendomains
	keepdir /etc/xen/auto
}

pkg_postinst() {
	elog "Official Xen Guide and the unoffical wiki page:"
	elog " http://www.gentoo.org/doc/en/xen-guide.xml"
	elog " http://en.gentoo-wiki.com/wiki/Xen/"

	if [[ "$(scanelf -s __guard -q $(type -P python))" ]] ; then
		echo
		ewarn "xend may not work when python is built with stack smashing protection (ssp)."
		ewarn "If 'xm create' fails with '<ProtocolError for /RPC2: -1 >', see bug #141866"
		ewarn "This probablem may be resolved as of Xen 3.0.4, if not post in the bug."
	fi

	if ! built_with_use dev-lang/python ncurses; then
		echo
		ewarn "NB: Your dev-lang/python is built without USE=ncurses."
		ewarn "Please rebuild python with USE=ncurses to make use of xenmon.py."
	fi

	if built_with_use sys-apps/iproute2 minimal; then
		echo
		ewarn "Your sys-apps/iproute2 is built with USE=minimal. Networking"
		ewarn "will not work until you rebuild iproute2 without USE=minimal."
	fi

	if ! use hvm; then
		echo
		elog "HVM (VT-x and AMD-V) support has been disabled. If you need hvm"
		elog "support enable the hvm use flag."
		elog "An x86 or amd64 multilib system is required to build HVM support."
		echo
		elog "The ioemu use flag has been removed and replaced with hvm."
	fi

	if grep -qsF XENSV= "${ROOT}/etc/conf.d/xend"; then
		echo
		elog "xensv is broken upstream (Gentoo bug #142011)."
		elog "Please remove '${ROOT%/}/etc/conf.d/xend', as it is no longer needed."
	fi
}
