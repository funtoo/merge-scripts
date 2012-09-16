# Distributed under the terms of the GNU General Public License v2

EAPI="3"

if [[ $PV == *9999 ]]; then
	KEYWORDS=""
	REPO="xen-unstable.hg"
	EHG_REPO_URI="http://xenbits.xensource.com/${REPO}"
	S="${WORKDIR}/${REPO}"
	live_eclass="mercurial"
else
	KEYWORDS="*"
	XEN_EXTFILES_URL="http://xenbits.xensource.com/xen-extfiles"
	SRC_URI="http://bits.xensource.com/oss-xen/release/${PV}/xen-${PV}.tar.gz \
	$XEN_EXTFILES_URL/ipxe-git-v1.0.0.tar.gz"
	S="${WORKDIR}/xen-${PV}"
fi

inherit flag-o-matic eutils multilib python toolchain-funcs ${live_eclass}

DESCRIPTION="Xend daemon and tools"
HOMEPAGE="http://xen.org/"

LICENSE="GPL-2"
SLOT="0"
IUSE="api custom-cflags debug doc flask hvm qemu pygrub screen xend"

CDEPEND="dev-lang/python
	dev-python/lxml
	sys-libs/zlib
	hvm? ( media-libs/libsdl
		sys-power/iasl )
	api? ( dev-libs/libxml2 net-misc/curl )"

DEPEND="${CDEPEND}
	sys-devel/gcc
	dev-lang/perl
	app-misc/pax-utils
	dev-ml/findlib
	doc? (
		app-doc/doxygen
		dev-tex/latex2html
		media-gfx/transfig
		media-gfx/graphviz
		dev-tex/xcolor
		dev-texlive/texlive-latexextra
		virtual/latex-base
		dev-tex/latexmk
		dev-texlive/texlive-latex
		dev-texlive/texlive-pictures
		dev-texlive/texlive-latexrecommended
	)
	hvm? (
		x11-proto/xproto
		sys-devel/dev86
	)"

RDEPEND="${CDEPEND}
	sys-apps/iproute2
	net-misc/bridge-utils
	dev-python/lxml
	>=dev-lang/ocaml-3.12.0
	screen? (
		app-misc/screen
		app-admin/logrotate
	)
	|| ( sys-fs/udev sys-apps/hotplug )"

# hvmloader is used to bootstrap a fully virtualized kernel
# Approved by QA team in bug #144032
QA_WX_LOAD="usr/lib/xen/boot/hvmloader"
QA_EXECSTACK="usr/share/xen/qemu/openbios-sparc32
	usr/share/xen/qemu/openbios-sparc64"

pkg_setup() {
	export "CONFIG_LOMOUNT=y"

	if use qemu; then
		export "CONFIG_IOEMU=y"
	else
		export "CONFIG_IOEMU=n"
	fi

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

	if use doc && ! has_version "dev-tex/latex2html[png,gif]"; then
		# die early instead of later
		eerror "USE=doc requires latex2html with image support. Please add"
		eerror "'png' and/or 'gif' to your use flags and re-emerge latex2html"
		die "latex2html missing both png and gif flags"
	fi

	if use pygrub && ! has_version "dev-lang/python[ncurses]"; then
		eerror "USE=pygrub requires python to be built with ncurses support. Please add"
		eerror "'ncurses' to your use flags and re-emerge python"
		die "python is missing ncurses flags"
	fi

	if ! has_version "dev-lang/python[threads]"; then
		eerror "Python is required to be built with threading support. Please add"
		eerror "'threads' to your use flags and re-emerge python"
		die "python is missing threads flags"
	fi

	use api     && export "LIBXENAPI_BINDINGS=y"
	use flask   && export "FLASK_ENABLE=y"

	if use hvm && ! use qemu; then
		elog "With qemu disabled, it is not possible to use HVM machines " \
			"or PVM machines with a framebuffer attached in the kernel config" \
			"The addition of use flag qemu is required when use flag hvm ise selected"
	fi
}

src_prepare() {
	cp "$DISTDIR/ipxe-git-v1.0.0.tar.gz" tools/firmware/etherboot/ipxe.tar.gz
	sed -e 's/-Wall//' -i Config.mk || die "Couldn't sanitize CFLAGS"
	# Drop .config
	sed -e '/-include $(XEN_ROOT)\/.config/d' -i Config.mk || die "Couldn't drop"
	# Xend
	if ! use xend; then
		sed -e 's:xm xen-bugtool xen-python-path xend:xen-bugtool xen-python-path:' \
			-i tools/misc/Makefile || die "Disabling xend failed"
		sed -e 's:^XEND_INITD:#XEND_INITD:' \
			-i tools/examples/Makefile || "Disabling xend failed"
	fi
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
		sed -e '/^CONFIG_IOEMU := y$/d' -i config/*.mk
		sed -e '/SUBDIRS-$(CONFIG_X86) += firmware/d' -i tools/Makefile
	fi

	if ! use pygrub; then
		sed -e '/^SUBDIRS-$(PYTHON_TOOLS) += pygrub$/d' -i tools/Makefile
	fi
	# Don't bother with qemu, only needed for fully virtualised guests
	if ! use qemu; then
		sed -e "/^CONFIG_IOEMU := y$/d" -i config/*.mk
		sed -e "s:install-tools\: tools/ioemu-dir:install-tools\: :g" \
			-i Makefile
	fi

	# Fix build for gcc-4.6
	sed -e "s:-Werror::g" -i  tools/xenstat/xentop/Makefile
	# Fix network broadcast on bridged networks
	epatch "${FILESDIR}/${PN}-3.4.0-network-bridge-broadcast.patch"

	# Do not strip binaries
	epatch "${FILESDIR}/${PN}-3.3.0-nostrip.patch"

	# Patch to libxl bug #380343
	epatch "${FILESDIR}/${PN}-4.1.1-libxl-tap.patch"

	# Patch from bug #382329 for hvmloader
	epatch "${FILESDIR}/${PN}-4.1.1-upstream-23104-1976adbf2b80.patch"

	# Prevent the downloading of ipxe
	sed -e 's:^\tif ! wget -O _$T:#\tif ! wget -O _$T:' \
		-e 's:^\tfi:#\tfi:' -i \
		-e 's:^\tmv _$T $T:#\tmv _$T $T:' \
		-i tools/firmware/etherboot/Makefile || die

	# Fix bridge by idella4, bug #362575
	epatch "${FILESDIR}/${P}-bridge.patch"

	# Patch for curl-config from bug #386487
	epatch "${FILESDIR}/${P}-curl.patch" || die

	# Patch for pyxml remove, Bug Funtoo http://jira.funtoo.org/browse/FL-102
	epatch "${FILESDIR}/${P}-pyxml-remove.patch" || die

	# Don't build ipxe with pie on hardened, Bug #360805
	if gcc-specs-pie ; then
		epatch "${FILESDIR}/ipxe-nopie.patch" || die "Could not apply ipxe-nopie patch"
	fi

	sed -e '/texi2html/ s/-number/&-sections/' \
		-i tools/ioemu-qemu-xen/Makefile || die #409333
}

src_compile() {
	export VARTEXFONTS="${T}/fonts"
	local myopt
	use debug && myopt="${myopt} debug=y"

	use custom-cflags || unset CFLAGS
	if test-flag-CC -fno-strict-overflow; then
		append-flags -fno-strict-overflow
	fi

	unset LDFLAGS
	emake CC=$(tc-getCC) LD=$(tc-getLD) -C tools ${myopt} || die "compile failed"

	if use doc; then
		sh ./docs/check_pkgs || die "package check failed"
		emake docs || die "compiling docs failed"
		emake dev-docs || die "make dev-docs failed"
	fi

	emake -C docs man-pages || die "make man-pages failed"
}

src_install() {
	# Override auto-detection in the build system, bug #382573
	export INITD_DIR=/etc/init.d
	export CONFIG_LEAF_DIR=default

	make DESTDIR="${D}" DOCDIR="/usr/share/doc/${PF}" XEN_PYTHON_NATIVE_INSTALL=y install-tools  \
		|| die "install failed"

	# Remove RedHat-specific stuff
	rm -r "${D}"/etc/init.d/xen* "${D}"/etc/default || die

	# uncomment lines in xl.conf
	sed -e 's:^#autoballoon=1:autoballoon=1:' \
		-e 's:^#lockfile="/var/lock/xl":lockfile="/var/lock/xl":' \
		-e 's:^#vifscript="vif-bridge":vifscript="vif-bridge":' \
		-i tools/examples/xl.conf  || die

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

	if use xend; then
		newinitd "${FILESDIR}"/xend.initd-r2 xend || die "Couldn't install xen.initd"
	fi
	newconfd "${FILESDIR}"/xendomains.confd xendomains \
		|| die "Couldn't install xendomains.confd"
	newinitd "${FILESDIR}"/xendomains.initd-r2 xendomains \
		|| die "Couldn't install xendomains.initd"
	newinitd "${FILESDIR}"/xenstored.initd xenstored \
		|| die "Couldn't install xenstored.initd"
	newconfd "${FILESDIR}"/xenstored.confd xenstored \
		|| die "Couldn't install xenstored.confd"
	newinitd "${FILESDIR}"/xenconsoled.initd xenconsoled \
		|| die "Couldn't install xenconsoled.initd"
	newconfd "${FILESDIR}"/xenconsoled.confd xenconsoled \
		|| die "Couldn't install xenconsoled.confd"

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
	elog " http://gentoo-wiki.com/HOWTO_Xen_and_Gentoo"

	if [[ "$(scanelf -s __guard -q $(type -P python))" ]] ; then
		echo
		ewarn "xend may not work when python is built with stack smashing protection (ssp)."
		ewarn "If 'xm create' fails with '<ProtocolError for /RPC2: -1 >', see bug #141866"
		ewarn "This probablem may be resolved as of Xen 3.0.4, if not post in the bug."
	fi

	if ! has_version "dev-lang/python[ncurses]"; then
		echo
		ewarn "NB: Your dev-lang/python is built without USE=ncurses."
		ewarn "Please rebuild python with USE=ncurses to make use of xenmon.py."
	fi

	if has_version "sys-apps/iproute2[minimal]"; then
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
		elog "The qemu use flag has been removed and replaced with hvm."
	fi
	if use xend; then
		echo
		elog "xend capability has been enabled and installed"
	fi
	if grep -qsF XENSV= "${ROOT}/etc/conf.d/xend"; then
		echo
		elog "xensv is broken upstream (Gentoo bug #142011)."
		elog "Please remove '${ROOT%/}/etc/conf.d/xend', as it is no longer needed."
	fi

	python_mod_optimize $(use pygrub && echo grub) xen
}

pkg_postrm() {
	python_mod_cleanup $(use pygrub && echo grub) xen
}
