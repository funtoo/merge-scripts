# Copyright owners: Gentoo Foundation
#                   Arfrever Frehtes Taifersar Arahesis
# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"

inherit flag-o-matic multilib-minimal toolchain-funcs versionator

MAJOR_VERSION="$(get_version_component_range 1)"
if [[ "${PV}" =~ ^[[:digit:]]+_rc[[:digit:]]*$ ]]; then
	MINOR_VERSION="1"
else
	MINOR_VERSION="$(get_version_component_range 2)"
fi

DESCRIPTION="International Components for Unicode"
HOMEPAGE="http://www.icu-project.org/"

BASE_URI="http://download.icu-project.org/files/icu4c/${PV/_/}"
SRC_ARCHIVE="icu4c-${PV//./_}-src.tgz"
DOCS_ARCHIVE="icu4c-${PV//./_}-docs.zip"

SRC_URI="${BASE_URI}/${SRC_ARCHIVE}
	doc? ( ${BASE_URI}/${DOCS_ARCHIVE} )"

LICENSE="BSD"
SLOT="0/${MAJOR_VERSION}"
KEYWORDS="*"
IUSE="c++11 debug doc examples static-libs"

DEPEND=""
RDEPEND=""

S="${WORKDIR}/${PN}/source"

QA_DT_NEEDED="/usr/lib.*/libicudata\.so\.${MAJOR_VERSION}\.${MINOR_VERSION}.*"
QA_FLAGS_IGNORED="/usr/lib.*/libicudata\.so\.${MAJOR_VERSION}\.${MINOR_VERSION}.*"

MULTILIB_CHOST_TOOLS=(
	/usr/bin/icu-config
)

src_unpack() {
	unpack "${SRC_ARCHIVE}"
	if use doc; then
		mkdir docs
		pushd docs > /dev/null
		unpack "${DOCS_ARCHIVE}"
		popd > /dev/null
	fi
}

src_prepare() {
	if use c++11; then
		if [[ "$(tc-getCXX)" == *g++* ]]; then
			if test-flag-CXX -std=gnu++11; then
				# Disable automatic detection of version of C++ standard.
				append-cxxflags -std=gnu++11
				# Store ABI flags in CXXFLAGS in icu-config and icu-*.pc files for API consumers.
				sed -e "/^CXXFLAGS =/s/ *$/ -std=gnu++11 -DUCHAR_TYPE=char16_t/" -i config/icu.pc.in config/Makefile.inc.in || die "sed failed"
			else
				eerror "GCC >=4.7 required for support for C++11"
				die "C++11 not supported by currently used C++ compiler"
			fi
		else
			if test-flag-CXX -std=c++11; then
				# Disable automatic detection of version of C++ standard.
				append-cxxflags -std=c++11
				# Store ABI flags in CXXFLAGS in icu-config and icu-*.pc files for API consumers.
				sed -e "/^CXXFLAGS =/s/ *$/ -std=c++11 -DUCHAR_TYPE=char16_t/" -i config/icu.pc.in config/Makefile.inc.in || die "sed failed"
			else
				die "C++11 not supported by currently used C++ compiler"
			fi
		fi
		# Set type of UChar in C++ mode to char16_t.
		append-cxxflags -DUCHAR_TYPE=char16_t
		# Hardcode type of UChar in C++ mode in installed headers.
		sed -e "/^    typedef UCHAR_TYPE UChar;$/a #elif defined(__cplusplus)\n    typedef char16_t UChar;" -i common/unicode/umachine.h || die "sed failed"
	else
		# Disable automatic detection of version of C++ standard.
		if [[ "$(tc-getCXX)" == *g++* ]]; then
			append-cxxflags -std=gnu++98
		else
			append-cxxflags -std=c++98
		fi
	fi

	sed -e "s/#define U_DISABLE_RENAMING 0/#define U_DISABLE_RENAMING 1/" -i common/unicode/uconfig.h || die "sed failed"

	multilib_copy_sources
}

multilib_src_configure() {
	econf \
		--disable-renaming \
		$(use_enable debug) \
		$(use_enable examples samples) \
		$(use_enable static-libs static) \
		CC="$(tc-getCC)" \
		CXX="$(tc-getCXX)"
}

multilib_src_compile() {
	emake VERBOSE="1"
}

multilib_src_test() {
	if [[ "${ABI}" == "x86" ]]; then
		# https://ssl.icu-project.org/trac/ticket/10614
		sed -e "/TESTCASE_AUTO(testGetSamples)/d" -i test/intltest/plurults.cpp
	fi

	# INTLTEST_OPTS: intltest options
	#   -e: Exhaustive testing
	#   -l: Reporting of memory leaks
	#   -v: Increased verbosity
	# IOTEST_OPTS: iotest options
	#   -e: Exhaustive testing
	#   -v: Increased verbosity
	# CINTLTST_OPTS: cintltst options
	#   -e: Exhaustive testing
	#   -v: Increased verbosity
	# LETEST_OPTS: letest options
	#   -e: Exhaustive testing
	#   -v: Increased verbosity
	emake -j1 VERBOSE="1" check
}

multilib_src_install() {
	emake DESTDIR="${D}" VERBOSE="1" install
}

multilib_src_install_all() {
	dohtml ../readme.html
	if use doc; then
		insinto /usr/share/doc/${PF}/html/api
		doins -r "${WORKDIR}/docs/"*
	fi
}
