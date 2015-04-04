# Distributed under the terms of the GNU General Public License v2

EAPI=5
PYTHON_COMPAT=( python{2_5,2_6,2_7} )
inherit eutils scons-utils toolchain-funcs multilib python-any-r1

DESCRIPTION="Framework for research and application development in the Audio and Music domain"
HOMEPAGE="http://clam-project.org/"
SRC_URI="http://clam-project.org/download/src/CLAM-${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~*"
IUSE="alsa debug doc double examples fft fftw jack ladspa mad optimize osc portaudio portmidi vorbis xercesc +xmlpp"

RDEPEND="dev-libs/libsigc++:2
	dev-util/cppunit
	media-libs/libsndfile
	sys-libs/zlib
	alsa? ( media-libs/alsa-lib )
	fftw? ( sci-libs/fftw:3.0 )
	jack? ( media-sound/jack-audio-connection-kit )
	ladspa? ( media-libs/ladspa-sdk )
	mad? ( media-libs/libmad
		   media-libs/id3lib )
	osc? ( media-libs/oscpack )
	portaudio? ( >=media-libs/portaudio-19_pre20111121 )
	portmidi? ( media-libs/portmidi )
	vorbis? ( media-libs/libvorbis
			  media-libs/libogg )
	xercesc? ( <dev-libs/xerces-c-3 )
	xmlpp? ( dev-cpp/libxmlpp:2.6 )"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	virtual/pkgconfig"

S=${WORKDIR}/CLAM-${PV}
RESTRICT="mirror"

pkg_setup()	{
	tc-export CC CXX
	python-any-r1_pkg_setup
}

src_prepare() {
	epatch "${FILESDIR}"/${P}/*.patch
}

src_configure() {
	local myconf=
	if use xercesc; then
		if use xmlpp; then
			myconf+=" xmlbackend=both"
		else
			myconf+=" xmlbackend=xercesc"
		fi
	else
		if use xmlpp; then
			myconf+=" xmlbackend=xmlpp"
		else
			myconf+=" xmlbackend=none"
		fi
	fi

	escons configure \
		prefix="${EPREFIX}/usr" \
		prefix_for_packaging="${ED}/usr" \
		libdir=$(get_libdir) \
		verbose=1 \
		release=$(use debug && echo 0 || echo 1) \
		$(use_scons alsa with_alsa) \
		$(use_scons double) \
		$(use_scons fft with_nr_fft) \
		$(use_scons fftw with_fftw3) \
		$(use_scons jack with_jack) \
		$(use_scons ladspa with_ladspa) \
		$(use_scons mad with_mad) \
		$(use_scons mad with_id3) \
		$(use_scons optimize optimize_and_lose_precision) \
		$(use_scons osc with_osc) \
		$(use_scons portaudio with_portaudio) \
		$(use_scons portmidi with_portmidi) \
		$(use_scons vorbis with_oggvorbis) \
		${myconf}

	escons --help
}

src_compile() {
	escons
	use doc && escons doxygen
}

src_install() {
	# force -j1 because of cryptic error creating pkgconfig files
	escons -j1 install

	dodoc CHANGES INSTALL

	if use doc; then
		dohtml -r doxygen/html/*
	fi

	if use examples; then
		docinto examples

		# want examples installed? will be more convenient uncompressed
		docompress -x /usr/share/doc/${PF}/examples

		dodoc -r examples/*
	fi
}
