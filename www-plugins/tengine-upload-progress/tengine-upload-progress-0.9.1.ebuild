# Distributed under the terms of the GNU General Public License v2

EAPI="5"

MY_PN=${PN/tengine-/}

DESCRIPTION="Is an implementation of an upload progress system, that monitors\
	RFC1867 POST upload as they are transmitted to upstream servers"
HOMEPAGE="https://github.com/masterzen/nginx-upload-progress-module"
SRC_URI="https://github.com/masterzen/nginx-${MY_PN}-module/archive/v${PV}.tar.gz -> ${P}.tar.gz"

RESTRICT="mirror"

SLOT="0"
LICENSE="BSD-2"
KEYWORDS="*"
IUSE=""

RDEPEND="www-servers/tengine[dso]"
DEPEND="${RDEPEND}"

S="${WORKDIR}/nginx-${MY_PN}-module-${PV}"

src_compile() {
	dso_tool --add-module="${S}" --dst="${S}"
}

src_install() {
	insinto "${EROOT}/var/lib/tengine/modules"
	doins "${S}/ngx_http_${MY_PN/-/}_module.so"
}
