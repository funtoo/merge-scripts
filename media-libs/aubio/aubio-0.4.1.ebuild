# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PYTHON_COMPAT=( python2_7 )

inherit distutils-r1 waf-utils multilib

DESCRIPTION="Library for audio labelling"
HOMEPAGE="http://aubio.org/"
SRC_URI="http://aubio.org/pub/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~*"
IUSE="doc double-precision examples ffmpeg fftw jack libsamplerate sndfile python"

RDEPEND="
	ffmpeg? ( virtual/ffmpeg )
	fftw? ( sci-libs/fftw:3.0 )
	jack? ( media-sound/jack-audio-connection-kit )
	libsamplerate? ( media-libs/libsamplerate )
	python? ( dev-python/numpy[${PYTHON_USEDEP}] ${PYTHON_DEPS} )
	sndfile? ( media-libs/libsndfile )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	app-text/txt2man
	doc? ( app-doc/doxygen )"

DOCS=( AUTHORS ChangeLog README.md )
PYTHON_SRC_DIR="${S}/python"

src_prepare() {
	sed -i -e "s:\/lib:\/$(get_libdir):" src/wscript_build || die
	sed -i -e "s:doxygen:doxygen_disabled:" wscript || die

	if use python ; then
		cd "${PYTHON_SRC_DIR}"
		distutils-r1_src_prepare
	fi
}

src_configure() {
	waf-utils_src_configure \
		--enable-complex \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		$(use_enable double-precision double) \
		$(use_enable fftw fftw3f) \
		$(use_enable fftw fftw3) \
		$(use_enable ffmpeg avcodec) \
		$(use_enable jack) \
		$(use_enable libsamplerate samplerate) \
		$(use_enable sndfile)

	if use python ; then
		cd "${PYTHON_SRC_DIR}"
		distutils-r1_src_configure
	fi
}

src_compile() {
	waf-utils_src_compile --notests

	if use doc; then
		cd "${S}"/doc
		doxygen full.cfg || die
	fi

	if use python ; then
		cd "${PYTHON_SRC_DIR}"
		distutils-r1_src_compile
	fi
}

src_test() {
	waf-utils_src_compile --alltests

	if use python ; then
		cd "${PYTHON_SRC_DIR}"
		distutils-r1_src_test
	fi
}

src_install() {
	waf-utils_src_install

	if use python ; then
		cd "${PYTHON_SRC_DIR}"
		DOCS="README" distutils-r1_src_install
	fi

	if use doc; then
		dodoc doc/*.txt
	fi

	if use examples; then
		# install dist_noinst_SCRIPTS from Makefile.am
		insinto /usr/share/doc/${PF}/examples
		doins examples/*
	fi
}
