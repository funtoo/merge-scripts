# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/xen-tools/xen-tools-3.3.1.ebuild,v 1.3 2009/04/28 07:57:21 patrick Exp $

EAPI="2"

inherit flag-o-matic eutils multilib python

# TPMEMUFILE=tpm_emulator-0.4.tar.gz

DESCRIPTION="Xend daemon and tools"
HOMEPAGE="http://xen.org/"
SRC_URI="http://bits.xensource.com/oss-xen/release/${PV}/xen-${PV}.tar.gz"
#	vtpm? ( mirror://berlios/tpm-emulator/${TPMEMUFILE} )"
S="${WORKDIR}/xen-${PV}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="doc debug screen custom-cflags pygrub hvm api acm flask"

CDEPEND="dev-lang/python[ncurses,threads]
	sys-libs/zlib
	hvm? ( media-libs/libsdl )
	acm? ( dev-libs/libxml2 )
	api? ( dev-libs/libxml2 net-misc/curl )"

DEPEND="${CDEPEND}
	sys-devel/gcc
	dev-lang/perl
	app-misc/pax-utils
	doc? (
		app-doc/doxygen
		dev-tex/latex2html[png,gif]
		dev-texlive/texlive-latexextra
		media-gfx/transfig
		media-gfx/graphviz
	)
	hvm? (
		x11-proto/xproto
		sys-devel/dev86
	)"

RDEPEND="${CDEPEND}
	sys-apps/iproute2[-minimal]
	net-misc/bridge-utils
	dev-python/pyxml
	screen? (
		app-misc/screen
		app-admin/logrotate
	)
	|| ( sys-fs/udev sys-apps/hotplug )"

PYTHON_MODNAME="xen grub"

# hvmloader is used to bootstrap a fully virtualized kernel
# Approved by QA team in bug #144032
QA_WX_LOAD="usr/lib/xen/boot/hvmloader"
QA_EXECSTACK="usr/share/xen/qemu/openbios-sparc32
	usr/share/xen/qemu/openbios-sparc64"

pkg_setup() {
	export "CONFIG_LOMOUNT=y"

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

#	use vtpm    && export "VTPM_TOOLS=y"
	use api     && export "LIBXENAPI_BINDINGS=y"
	use acm     && export "ACM_SECURITY=y"
	use flask   && export "FLASK_ENABLE=y"
}

src_unpack() {
	unpack ${A}
	cd "${S}"
#	use vtpm && cp "${DISTDIR}"/${TPMEMUFILE}  tools/vtpm

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
		sed -i -e '/^SUBDIRS-$(PYTHON_TOOLS) += pygrub$/d' "${S}"/tools/Makefile
	fi

	# Fix network broadcast on bridged networks
	epatch "${FILESDIR}/${PN}-3.1.3-network-bridge-broadcast.patch"

	# Fix building small dumb utility called 'xen-detect' on hardened
	epatch "${FILESDIR}/${PN}-3.3.0-xen-detect-nopie-fix.patch"

	# Do not strip binaries
	epatch "${FILESDIR}/${PN}-3.3.0-nostrip.patch"

	# Fix sandbox violation as per Bug 253134
	# http://bugzilla.xensource.com/bugzilla/show_bug.cgi?id=1405
	epatch "${FILESDIR}/${PN}-3.3.1-sandbox-fix.patch"

	# Fix eqemu-xen (Bug 262124)
	epatch "${FILESDIR}/${PN}-3.3.1-qemu-xen.patch"

	# Use udevadm intead of udevinfo (Bug 236819)
	epatch "${FILESDIR}/${PN}-3.3.1-udevadm-fix.diff"

	# Fix e1000 support (Bug 239425)
	epatch "${FILESDIR}/${PN}-3.3.1-e1000.patch"

	# Get rid of deprecation warnings with python 2.6:
	epatch "${FILESDIR}/${PN}-3.3.1-python-2.6.patch"
}

src_compile() {
	export VARTEXFONTS="${T}/fonts"
	local myopt
	use debug && myopt="${myopt} debug=y"

	use custom-cflags || unset CFLAGS
	if test-flag-CC -fno-strict-overflow; then
		append-flags -fno-strict-overflow
	fi

	emake -C tools ${myopt} || die "compile failed"

	if use doc; then
		sh ./docs/check_pkgs || die "package check failed"
		emake docs || die "compiling docs failed"
		emake dev-docs || die "make dev-docs failed"
	fi

	emake -C docs man-pages || die "make man-pages failed"
}

src_install() {
	make DESTDIR="${D}" DOCDIR="/usr/share/doc/${PF}" XEN_PYTHON_NATIVE_INSTALL=y install-tools  \
		|| die "install failed"

	# Remove RedHat-specific stuff
	rm -rf "${D}"/etc/sysconfig

	dodoc README docs/README.xen-bugtool docs/ChangeLog
	if use doc; then
		emake DESTDIR="${D}" DOCDIR="/usr/share/doc/${PF}" install-docs \
			|| die "install docs failed"

		dohtml -r docs/api/
		docinto pdf
		dodoc docs/api/tools/python/latex/refman.pdf

		[ -d "${D}"/usr/share/doc/xen ] && mv "${D}"/usr/share/doc/xen/* "${D}"/usr/share/doc/${PF}/html
	fi
	rm -rf "${D}"/usr/share/doc/xen/

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

	# The network-null script doesn't do anything funky to our network
	# configuration, so we use it as a safe default:

	exeinto /etc/xen/scripts
	doexe ${FILESDIR}/network-null
	dosed '/^(network-script/c(network-script network-null)' /etc/xen/xend-config.sxp

}

pkg_postinst() {
	elog "Xen-tools no longer modifies your network configuration by default."
	elog "To enable prior behavior, modify the \"(network-script network-null)\" line in "
	elog "/etc/xen/xend-config.sxp to read \"(network-script network-bridge)\"."
	elog
	elog "Official Xen Guide and the unoffical wiki page:"
	elog " http://www.gentoo.org/doc/en/xen-guide.xml"
	elog " http://gentoo-wiki.com/HOWTO_Xen_and_Gentoo"

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

	python_mod_optimize
}

pkg_postrm() {
	python_mod_cleanup
}
