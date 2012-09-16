# Distributed under the terms of the GNU General Public License v2

EAPI="3"

inherit base flag-o-matic eutils multilib python toolchain-funcs

# TPMEMUFILE=tpm_emulator-0.4.tar.gz

DESCRIPTION="Xend daemon and tools"
HOMEPAGE="http://xen.org/"
SRC_URI="http://bits.xensource.com/oss-xen/release/${PV}/xen-${PV}.tar.gz"
#	vtpm? ( mirror://berlios/tpm-emulator/${TPMEMUFILE} )"
S="${WORKDIR}/xen-${PV}"
QA_PRESTRIPPED="/usr/share/xen/qemu/openbios-ppc \
	/usr/share/xen/qemu/openbios-sparc64 \
	/usr/share/xen/qemu/openbios-sparc32"
QA_WX_LOAD="${QA_PRESTRIPPED}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="doc debug screen custom-cflags pygrub hvm api acm flask"

CDEPEND="dev-lang/python[ncurses,threads]
	sys-libs/zlib
	hvm? ( media-libs/libsdl )
	acm? ( dev-libs/libxml2 )
	api? ( dev-libs/libxml2 net-misc/curl )"
#	vtpm? ( dev-libs/gmp dev-libs/openssl )

DEPEND="${CDEPEND}
	sys-devel/gettext
	sys-devel/gcc
	dev-lang/perl
	dev-lang/python[ssl]
	app-misc/pax-utils
	doc? (
		app-doc/doxygen
		dev-tex/latex2html[png,gif]
		media-gfx/transfig
		media-gfx/graphviz
		virtual/latex-base
		dev-tex/latexmk
		dev-texlive/texlive-latex
		dev-texlive/texlive-pictures
		dev-texlive/texlive-latexextra
		dev-texlive/texlive-latexrecommended
	)
	hvm? (
		x11-proto/xproto
		sys-devel/dev86
	)"

RDEPEND="${CDEPEND}
	sys-apps/iproute2
	net-misc/bridge-utils
	dev-python/pyxml
	screen? (
		app-misc/screen
		app-admin/logrotate
	)
	|| ( sys-fs/udev sys-apps/hotplug )"

PATCHES=(
	"${FILESDIR}/${PN}-3.4.0-network-bridge-broadcast.patch"
	"${FILESDIR}/${PN}-3.3.0-nostrip.patch"
	"${FILESDIR}/${PN}-3.3.1-sandbox-fix.patch"
	"${FILESDIR}/${P}-as-needed.patch"
	"${FILESDIR}/${P}-fix-definitions.patch"
	"${FILESDIR}/${P}-fix-include.patch"
	"${FILESDIR}/${P}-werror-idiocy-v2.patch"
	"${FILESDIR}/${P}-ldflags-respect.patch"
)

# hvmloader is used to bootstrap a fully virtualized kernel
# Approved by QA team in bug #144032
QA_WX_LOAD="usr/lib/xen/boot/hvmloader"
QA_EXECSTACK="usr/share/xen/qemu/openbios-sparc32
	usr/share/xen/qemu/openbios-sparc64"

pkg_setup() {
	if [ -x /.config/ ]; then
		die "the system has a dir /.config; this needs to be removed to allow the package to emerge"
	fi

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

src_prepare() {
	base_src_prepare

	#	use vtpm && cp "${DISTDIR}"/${TPMEMUFILE}  tools/vtpm

	# if the user *really* wants to use their own custom-cflags, let them
	# Try and remove all the default custom-cflags
	if use custom-cflags; then
		epatch "${FILESDIR}/${P}-remove-default-cflags.patch"
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

	emake CC=$(tc-getCC) LD=$(tc-getLD) -C tools ${myopt} || die "compile failed"

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

	# Remove unneeded static-libs
	rm "${D}"/usr/lib64/libxenctrl.a "${D}"/usr/lib64/libxenguest.a \
	"${D}"/usr/lib64/libflask.a "${D}"/usr/lib64/libxenstore.a \
	"${D}"/usr/lib64/libblktap.a "${D}"/usr/lib64/libxenapi.a

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

	newinitd "${FILESDIR}"/xend.initd-r1 xend \
		|| die "Couldn't install xen.initd"
	newconfd "${FILESDIR}"/xendomains.confd xendomains \
		|| die "Couldn't install xendomains.confd"
	newinitd "${FILESDIR}"/xendomains.initd-r1 xendomains \
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
		elog "The ioemu use flag has been removed and replaced with hvm."
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
