# Copyright (C) 2013 Jonathan Vasquez <jvasquez1011@gmail.com>
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

NAME="btsync"
DESCRIPTION="Automatically sync files via secure, distributed technology."
HOMEPAGE="http://labs.bittorrent.com/experiments/sync.html"
SRC_URI="
	amd64?	( http://syncapp.bittorrent.com/${PV}/btsync_x64-${PV}.tar.gz )
	x86?	( http://syncapp.bittorrent.com/${PV}/btsync_i386-${PV}.tar.gz )
	arm?	( http://syncapp.bittorrent.com/${PV}/btsync_arm-${PV}.tar.gz )
	ppc?	( http://syncapp.bittorrent.com/${PV}/btsync_powerpc-${PV}.tar.gz )"

RESTRICT="mirror strip"
LICENSE="BitTorrent"
SLOT="0"
KEYWORDS="amd64 ~x86 ~arm ~ppc"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

QA_PREBUILT="opt/btsync/btsync"

S="${WORKDIR}"

src_install() {
	mkdir -p ${D}/opt/${NAME} && cd ${D}/opt/${NAME}
	mkdir -p ${D}/etc/{init.d,${NAME}}

	cp ${S}/btsync .
	cp ${S}/LICENSE.TXT .
	./btsync --dump-sample-config > ${D}/etc/${NAME}/config
	cp ${FILESDIR}/init.d/${NAME} ${D}/etc/init.d/

	# Set more secure permissions
	chmod 755 ${D}/etc/init.d/btsync
}
