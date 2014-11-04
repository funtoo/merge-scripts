# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PYTHON_COMPAT=( python2_{6,7} python3_{2,3} )
DISTUTILS_OPTIONAL=1
inherit distutils-r1 eutils libtool multilib

NL_P=${P/_/-}

DESCRIPTION="A collection of libraries providing APIs to netlink protocol based Linux kernel interfaces"
HOMEPAGE="http://www.infradead.org/~tgr/libnl/"
SRC_URI="
	http://www.infradead.org/~tgr/${PN}/files/${NL_P}.tar.gz
"
LICENSE="LGPL-2.1 utils? ( GPL-2 )"
SLOT="3"
KEYWORDS="*"
IUSE="static-libs python utils"

RDEPEND="python? ( ${PYTHON_DEPS} )"
DEPEND="${RDEPEND}
	python? ( dev-lang/swig )
	sys-devel/flex
	sys-devel/bison
"

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

DOCS=( ChangeLog )

S=${WORKDIR}/${NL_P}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-1.1-vlan-header.patch
	epatch "${FILESDIR}"/${PN}-3.2.20-rtnl_tc_get_ops.patch
	epatch "${FILESDIR}"/${PN}-3.2.20-cache-api.patch
	epatch "${FILESDIR}"/${PN}-3.2.23-python.patch

	elibtoolize

	if use python; then
		cp "${FILESDIR}"/${P}-utils.h python/netlink/utils.h || die
		cd "${S}"/python || die
		distutils-r1_src_prepare
	fi
}

src_configure() {
	econf \
		--disable-silent-rules \
		$(use_enable static-libs static) \
		$(use_enable utils cli)

	if use python; then
		cd "${S}"/python || die
		distutils-r1_src_configure
	fi
}

src_compile() {
	default

	if use python; then
		cd "${S}"/python || die
		distutils-r1_src_compile
	fi
}

src_install() {
	default

	if use python; then
		# Unset DOCS= since distutils-r1.eclass interferes
		DOCS=''
		cd "${S}"/python || die
		distutils-r1_src_install
	fi

	prune_libtool_files $(usex static-libs --modules --all)
}
