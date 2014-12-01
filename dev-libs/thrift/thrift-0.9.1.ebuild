# Distributed under the terms of the GNU General Public License v2

EAPI="5-progress"
PYTHON_MULTIPLE_ABIS="1"
PYTHON_RESTRICTED_ABIS="3.* *-jython *-pypy"
PYTHON_DEPEND="python? ( <<>> )"
GENTOO_DEPEND_ON_PERL="no"

inherit autotools eutils distutils perl-module

DESCRIPTION="Lightweight, language-independent software stack with associated code generation mechanism for RPC"
HOMEPAGE="http://thrift.apache.org"
SRC_URI="mirror://apache/${PN}/${PV}/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE="+cpp +glib event perl +python qt4 static-libs test +zlib"

RDEPEND="cpp? ( dev-libs/boost:= )
	event? ( dev-libs/libevent )
	glib? ( dev-libs/glib:2 )
	perl? ( dev-lang/perl:= dev-perl/Bit-Vector )
	qt4? ( dev-qt/qtcore:4 )
	zlib? ( sys-libs/zlib )"

DEPEND="${RDEPEND}
	python? ( $(python_abi_depend dev-python/setuptools) )
	virtual/pkgconfig"

pkg_setup() {
	use python && python_pkg_setup
}

src_prepare() {
	epatch "${FILESDIR}"/0.9.1-autoconf-fixes.patch

	# fixed in 1.0-dev
	sed -i -e 's|tutorial||' Makefile.am || die

	AT_NO_RECURSIVE=1 eautoreconf

	if use python ; then
		cd "${S}"/lib/py
		distutils_src_prepare
	fi
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_enable test) \
		$(use_with cpp) \
		$(use_with cpp boost) \
		$(use_with event libevent) \
		$(use_with glib c_glib) \
		$(use_with qt4 qt) \
		$(use_with zlib) \
		--without-{python,perl} \
		--without-{csharp,java,erlang,php,php_extension,ruby,haskell,go,d,nodejs}

	if use perl ; then
		cd "${S}"/lib/perl
		perl-module_src_configure
	fi
}

src_compile() {
	default

	if use perl ; then
		cd "${S}"/lib/perl
		perl-module_src_compile
	fi

	if use python ; then
		cd "${S}"/lib/py
		distutils_src_compile
	fi
}

src_install() {
	default
	prune_libtool_files

	if use perl ; then
		cd "${S}"/lib/perl
	perl-module_src_install
	fi

	if use python ; then
	cd "${S}"/lib/py
	distutils_src_install
	fi
}

pkg_postinst() {
	use python && distutils_pkg_postinst
}

pkg_postrm() {
	use python && distutils_pkg_postrm
}	
