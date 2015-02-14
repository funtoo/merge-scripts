# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit eutils user

MAN_PKG="man-1.6g"
MAN2HTML_SRC="http://primates.ximian.com/~flucifredi/man/${MAN_PKG}.tar.gz"

DESCRIPTION="a man replacement that utilizes berkdb instead of flat files"
HOMEPAGE="http://www.nongnu.org/man-db/"
SRC_URI="http://download.savannah.nongnu.org/releases/man-db/${P}.tar.xz
	${MAN2HTML_SRC}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="*"
IUSE="berkdb +gdbm lzma nls static-libs zlib"

RDEPEND=">=dev-libs/libpipeline-1.3.0
	berkdb? ( sys-libs/db )
	gdbm? ( sys-libs/gdbm )
	!berkdb? ( !gdbm? ( sys-libs/gdbm ) )
	|| ( sys-apps/groff >=app-doc/heirloom-doctools-080407-r2 )
	zlib? ( sys-libs/zlib )
	!sys-apps/man"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	nls? (
		app-text/po4a
		sys-devel/gettext
	)
	virtual/pkgconfig"	

pkg_setup() {
	# Create user now as Makefile in src_install does setuid/chown
	enewgroup man 15
	enewuser man 13 -1 /usr/share/man man
}


src_prepare() {
	# FL-258 build man package so we can extract man2html
	cd "${WORKDIR}"/"${MAN_PKG}"
	epatch "${FILESDIR}"/man-1.6f-man2html-compression-2.patch
	epatch "${FILESDIR}"/man-1.6-cross-compile.patch
	epatch "${FILESDIR}"/man-1.6f-unicode.patch #146315
	epatch "${FILESDIR}"/man-1.6c-cut-duplicate-manpaths.patch
	epatch "${FILESDIR}"/man-1.5m2-apropos.patch
	epatch "${FILESDIR}"/man-1.6g-fbsd.patch #138123
	epatch "${FILESDIR}"/man-1.6e-headers.patch
	epatch "${FILESDIR}"/man-1.6f-so-search-2.patch
	epatch "${FILESDIR}"/man-1.6g-compress.patch #205147
	epatch "${FILESDIR}"/man-1.6f-parallel-build.patch #207148 #258916
	epatch "${FILESDIR}"/man-1.6g-xz.patch #302380
	epatch "${FILESDIR}"/man-1.6f-makewhatis-compression-cleanup.patch #331979

	# make sure `less` handles escape sequences #287183
	sed -i -e '/^DEFAULTLESSOPT=/s:"$:R":' configure
}

src_configure() {
	export ac_cv_lib_z_gzopen=$(usex zlib)
	econf \
		--docdir='$(datarootdir)'/doc/${PF} \
		--enable-setuid \
		--with-sections="1 1p 8 2 3 3p 4 5 6 7 9 0p tcl n l p o 1x 2x 3x 4x 5x 6x 7x 8x" \
		$(use_enable nls) \
		$(use_enable static-libs static) \
		--with-db=$(usex gdbm gdbm $(usex berkdb db gdbm))

	# FL-258 build man package so we can extract man2html
	cd "${WORKDIR}"/"${MAN_PKG}"	
	strip-linguas $(eval $(grep ^LANGUAGES= configure) ; echo ${LANGUAGES//,/ })
	unset NLSPATH #175258
	tc-export CC BUILD_CC
	local mylang=
	if use nls ; then
		if [[ -z ${LINGUAS} ]] ; then
			mylang="all"
		else
			mylang="${LINGUAS// /,}"
		fi
	else
		mylang="none"
	fi
	export COMPRESS
	if use lzma ; then
		COMPRESS=/usr/bin/xz
	else
		COMPRESS=/bin/bzip2
	fi
	./configure -confdir=/etc +sgid +fhs +lang ${mylang} || die "configure failed in man"
}

src_compile() {
	cd "${S}"
	emake || die "emake failed in man-db"

	# FL-258 build man package so we can extract man2html
	cd "${WORKDIR}"/"${MAN_PKG}"
	make || die "emake failed in man"
}

src_install() {
	cd "${S}"
	emake install DESTDIR="${D}" || die
	dodoc README ChangeLog NEWS docs/{HACKING,TODO}
	prune_libtool_files

	exeinto /etc/cron.daily
	newexe "${FILESDIR}"/man-db.cron man-db #289884

	keepdir /var/cache/man
	fowners man:root /var/cache/man
	fperms 2755 /var/cache/man

	# FL-258 Install just the man2html part of man.
	cd "${WORKDIR}"/"${MAN_PKG}"/man2html
	make PREFIX="${D}" install || die "make install failed for man2html"
}

pkg_preinst() {
	if [[ -f ${EROOT}var/cache/man/whatis ]] ; then
		einfo "Cleaning ${EROOT}var/cache/man from sys-apps/man"
		find "${EROOT}"var/cache/man -type f '!' '(' -name index.bt -o -name index.db ')' -delete
	fi
	if [[ ! -g ${EROOT}var/cache/man ]] ; then
		einfo "Resetting permissions on ${EROOT}var/cache/man" #447944
		mkdir -p "${EROOT}var/cache/man"
		chown -R man:root "${EROOT}"var/cache/man
		find "${EROOT}"var/cache/man -type d '!' -perm /g=s -exec chmod 2755 {} +
	fi
}

pkg_postinst() {
	if [[ "${EROOT}" = "/" ]] ; then
		einfo "Generating/updating man-db cache..."
		/etc/cron.daily/man-db
	fi
}
