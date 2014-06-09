# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit eutils toolchain-funcs multilib systemd

DESCRIPTION="Userspace utilities for the Linux kernel cpufreq subsystem"
HOMEPAGE="http://www.kernel.org/pub/linux/utils/kernel/cpufreq/cpufrequtils.html"
SRC_URI="mirror://kernel/linux/utils/kernel/cpufreq/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="debug nls"

DEPEND="nls? ( virtual/libintl )"
RDEPEND=""

ft() { use $1 && echo true || echo false ; }

src_prepare() {
	epatch "${FILESDIR}"/${PN}-007-build.patch
	epatch "${FILESDIR}"/${PN}-007-nls.patch #205576 #292246
	epatch "${FILESDIR}"/${PN}-008-remove-pipe-from-CFLAGS.patch #362523
	epatch "${FILESDIR}"/${PN}-008-cpuid.patch
	epatch "${FILESDIR}"/${PN}-008-fix-msr-read.patch
	epatch "${FILESDIR}"/${PN}-008-increase-MAX_LINE_LEN.patch
	epatch "${FILESDIR}"/${PN}-008-fix-compilation-on-x86-32-with-fPIC.patch #375967
}

src_configure() {
	export DEBUG=$(ft debug) V=true NLS=$(ft nls)
	unset bindir sbindir includedir localedir confdir
	export mandir="/usr/share/man"
	export libdir="/usr/$(get_libdir)"
	export docdir="/usr/share/doc/${PF}"
}

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		LD="$(tc-getCC)" \
		AR="$(tc-getAR)" \
		STRIP=: \
		RANLIB="$(tc-getRANLIB)" \
		LIBTOOL="${EPREFIX}"/usr/bin/libtool \
		INSTALL="${EPREFIX}"/usr/bin/install
}

src_install() {
	# There's no configure script, so in this case we have to use emake
	# DESTDIR="${ED}" instead of the usual econf --prefix="${EPREFIX}".
	emake DESTDIR="${ED}" install
	dodoc AUTHORS README

	exeinto /usr/libexec
	doexe "${FILESDIR}/cpufrequtils-change.sh"

	systemd_dounit "${FILESDIR}/cpufrequtils.service"
	newinitd "${FILESDIR}"/${PN}-init.d-007 ${PN}
	newconfd "${FILESDIR}"/${PN}-conf.d-006 ${PN}
}
