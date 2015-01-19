# Distributed under the terms of the GNU General Public License v2

EAPI="5"

DESCRIPTION="Ghost blogging platform. Ghost allows you to write and publish your own blog, giving you the tools to make it easy and even fun to do."
HOMEPAGE="https://ghost.org"
SRC_URI="https://ghost.org/zip/ghost-0.5.8.zip"

LICENSE="MIT"
KEYWORDS="*"

RDEPEND="net-libs/nodejs[npm]"
DEPEND="${RDEPEND} \
app-arch/unzip"

SLOT="0"

S=${WORKDIR}

src_install() {
    install -d ${D}/usr/share/webapps/ghost/
    cp -r ${S}/* ${D}/usr/share/webapps/ghost/
}

pkg_postinst() {
    elog "To start Ghost run:"
    elog "npm install --production"
    elog "Followed by:"
    elog "npm start --production"
    ewarn "Configure Ghost in /usr/share/webapp/ghost/config.example.js and rename it to config.js"
}
