EAPI=5

inherit autotools

DESCRIPTION="A powerful but simple cron replacement."
HOMEPAGE="http://people.redhat.com/~rjones/whenjobs https://bitbucket.org/golodhrim/whenjobs"
SRC_URI="https://bitbucket.org/golodhrim/whenjobs/get/${PVR}-funtoo.tar.gz -> ${P}.tar.gz"

SLOT="0"

LICENSE="GPL-2"
KEYWORDS=""

DEPEND="
	>=dev-lang/ocaml-4.00.1
	>=dev-ml/calendar-2.03.2
	>=dev-ml/ocamlnet-3.6.1 
	>=mail-client/mailx-8.1.2.20050715-r6"

src_unpack() {
        unpack ${A}
	whenjobs=$(ls -d ${WORKDIR}/*/)
	mv ${whenjobs} ${WORKDIR}/${P}
}

src_prepare() {
	eautoreconf || die
}

src_configure() {
        econf --prefix=/usr || die
}

src_install() {
	emake DESTDIR="${D}" install || die

	# Install initial config with only root as allowed user
	insinto /etc
	newins "${FILESDIR}/whenjobs.users.conf" whenjobs.users.conf || die
	
	# Install Docs
	dodoc COPYING README TODO || die
}