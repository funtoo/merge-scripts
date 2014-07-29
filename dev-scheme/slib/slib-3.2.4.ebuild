# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit eutils versionator

#version magic thanks to masterdriverz and UberLord using bash array instead of tr
trarr="0abcdefghi"
MY_PV="$(get_version_component_range 1)${trarr:$(get_version_component_range 2):1}$(get_version_component_range 3)"

DESCRIPTION="A portable Scheme library providing compatibiliy and utility functions for all standard Scheme implementations"
HOMEPAGE="http://people.csail.mit.edu/jaffer/SLIB"
SRC_URI="http://swiss.csail.mit.edu/ftpdir/scm/${PN}-${MY_PV}.tar.gz"

RESTRICT="mirror"

LICENSE="public-domain BSD"
SLOT="0"
KEYWORDS="*"
IUSE="bigloo drscheme elk gambit mit-scheme scm"

RDEPEND="
	>=sys-apps/texinfo-5.0
	>=dev-scheme/guile-2.0.9

	bigloo? ( dev-scheme/bigloo )
	drscheme? ( dev-scheme/drscheme )
	elk? ( dev-scheme/elk )
	gambit? ( dev-scheme/gambit )
	mit-scheme? ( dev-scheme/mit-scheme )
	scm? ( dev-scheme/scm )"
DEPEND="${RDEPEND}"

S=${WORKDIR}/${PN}-${MY_PV}

src_prepare() {
	# From Slib
	# 	http://cvs.savannah.gnu.org/viewvc/slib/slib/
	epatch "${FILESDIR}"/"${P}"-backport-texlive-5-fix-and-other-changes.patch

	sed -i 's|usr/lib|usr/share|' RScheme.init
	sed -i 's|usr/local|usr/share|' gambit.init
}

src_configure() {
	./configure --prefix=/usr --libdir=/usr/share

	sed -i -e 's# scm$# guile#;s#ginstall-info#install-info#' -e 's/no-split -o/no-split --force -o/' Makefile
}

src_compile() {
	emake

	makeinfo -o slib.txt --plaintext --force slib.texi
	makeinfo -o slib.html --html --no-split --force slib.texi
}

src_install() {
	# core
	dodir /usr/share/slib
	insinto /usr/share/slib
	doins *.dat
	doins *.init
	doins *.ps
	doins *.scm
	doins *.sh

	# bin
	dosym /usr/share/slib/${PN}.sh /usr/bin/${PN}

	# env
	dodir /etc/env.d/
	echo "SCHEME_LIBRARY_PATH=\"${EPREFIX}/usr/share/slib/\"" > "${ED}"/etc/env.d/50slib

	# docs
	dodoc ANNOUNCE COPYING FAQ README ChangeLog slib.{txt,html} || die

	doinfo slib.info || die

	doman slib.1 || die

	# guile
	dosym /usr/share/slib/ /usr/share/guile/2.0/

	dodir /usr/share/guile/site/2.0/

	# backwards compatibility
	dosym /usr/share/slib/ /usr/lib/slib
}

make_load_expression() {
	echo "(load \\\"${EPREFIX}${INSTALL_DIR}$1.init\\\")"
}

pkg_postinst() {
	# permissions
	chmod 755 /usr/share/slib/*.sh

	# catalogs
	guile -c "(use-modules (ice-9 slib)) (require 'new-catalog)"

	if use bigloo ; then
		bigloo -s -eval "(begin $(make_load_expression bigloo) (require 'new-catalog) (exit))"
	fi

	if use drscheme ; then
		mzscheme -vme "(begin $(make_load_expression mzscheme) (require 'new-catalog))"
	fi

	if use elk ; then
		echo "$(make_load_expression elk) (require 'new-catalog)" | elk -l -
	fi

	if use gambit ; then
		gambit-interpreter -e "$(make_load_expression gambit) (require 'new-catalog)"
	fi

	if use mit-scheme ; then
		echo "(set! load/suppress-loading-message? #t) $(make_load_expression mitscheme) (require 'new-catalog)" | mit-scheme --batch-mode
	fi

	if use scm ; then
		scm -e "(require 'new-catalog)"
	fi
}

pkg_prerm() {
    # temp
    [[ -d "${ROOT}/usr/share/guile/site/2.0/" ]] && rm -rf "${ROOT}/usr/share/guile/site/2.0/"
}
