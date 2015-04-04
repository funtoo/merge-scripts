# Distributed under the terms of the GNU General Public License v2

EAPI="5"

MY_PN=${PN/tengine-/}

DESCRIPTION="Upstream module for the Redis 2.0 protocol"
HOMEPAGE="https://github.com/openresty/redis2-nginx-module"
SRC_URI="https://github.com/openresty/${MY_PN}-nginx-module/archive/v${PV}.tar.gz -> ${P}.tar.gz"

RESTRICT="mirror"

SLOT="0"
LICENSE="BSD-2"
KEYWORDS="*"
IUSE=""

RDEPEND="www-servers/tengine[dso]"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_PN}-nginx-module-${PV}"

src_compile() {
	dso_tool --add-module="${S}" --dst="${S}"
}

src_install() {
	insinto "${EROOT}/var/lib/tengine/modules"
	doins "${S}/ngx_http_${MY_PN}_module.so"
}
