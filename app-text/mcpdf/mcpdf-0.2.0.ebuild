# Distributed under the terms of the GNU General Public License v2

EAPI="5"

DESCRIPTION="A drop-in replacement for PDFtk."
HOMEPAGE="https://github.com/m-click/mcpdf"
SRC_URI="https://oss.sonatype.org/content/repositories/releases/aero/m-click/${PN}/${PV}/${P}-jar-with-dependencies.jar"

LICENSE="as-is"
SLOT="0"
KEYWORDS="~*"
IUSE="+pdftk"

RDEPEND="pdftk? ( !app-text/pdftk )"
DEPEND="${RDEPEND}
    >=virtual/jre-1.4
"

src_unpack() {
    mkdir ${WORKDIR}/${P}
}

src_install() {
    # install jar archive
    dodir /opt/${PN}
    insinto /opt/${PN}
    newins ${DISTDIR}/${A} ${PN}.jar

    # install wrapper
    newbin ${FILESDIR}/${PN} ${PN}

    if use pdftk ; then
        # setup symlink
        insinto /usr/bin
        dosym /usr/bin/${PN} /usr/bin/pdftk
    fi
}
