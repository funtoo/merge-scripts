# Distributed under the terms of the GNU General Public License v2

EAPI="2"

inherit eutils

MAN_PKG="man-1.6g"
MAN2HTML_SRC="http://primates.ximian.com/~flucifredi/man/${MAN_PKG}.tar.gz"

DESCRIPTION="a man replacement that utilizes berkdb instead of flat files"
HOMEPAGE="http://www.nongnu.org/man-db/"
SRC_URI="http://download.savannah.nongnu.org/releases/man-db/${P}.tar.gz
	${MAN2HTML_SRC}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~*"
IUSE="berkdb +gdbm nls zlib"

RDEPEND="dev-libs/libpipeline
	berkdb? ( sys-libs/db )
	gdbm? ( sys-libs/gdbm )
	!berkdb? ( !gdbm? ( sys-libs/gdbm ) )
	|| ( sys-apps/groff >=app-doc/heirloom-doctools-080407-r2 )
	zlib? ( sys-libs/zlib )
	!sys-apps/man"
DEPEND="
	${RDEPEND}
	nls? ( sys-devel/gettext )"

pkg_setup() {
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
	local db="gdbm"
	use berkdb && ! use gdbm && db="db"
	export ac_cv_lib_z_gzopen=$(usex zlib)
	econf \
		--with-sections="1 1p 8 2 3 3p 4 5 6 7 9 0p tcl n l p o 1x 2x 3x 4x 5x 6x 7x 8x" \
		$(use_enable nls) \
		--with-db=${db}
		--docdir=/usr/share/doc/${PF} \
		--enable-setuid

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
	exeinto /etc/cron.daily
	newexe $FILESDIR/man-db.cron man-db || die

	# FL-258 Install just the man2html part of man.
	cd "${WORKDIR}"/"${MAN_PKG}"/man2html
	make PREFIX="${D}" install || die "make install failed for man2html"
	
}

pkg_preinst() {
	if [ -f "${ROOT}var/cache/man/whatis" ]
	then
	   einfo "Cleaning stale ${ROOT}var/cache/man directory..."
	   rm -rf "${ROOT}var/cache/man"
	fi
	einfo "Ensuring ${ROOT}var/cache/man has correct permissions and
	ownership..."
	install -o man 0g root -m2775 -d man:root "$ROOT/var/cache/man" || die
}

pkg_postinst() {
	if [ "$ROOT" = "/" ]
	then
		einfo  "Generating/updating man-db cache..."
		/etc/cron.daily/man-db
	fi
}



















