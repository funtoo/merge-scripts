# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit distutils

EAPI=2

MY_P="Coherence-${PV}"

DESCRIPTION="Coherence is a framework written in Python for DLNA/UPnP components"
HOMEPAGE="https://coherence.beebits.net/"
SRC_URI="http://coherence.beebits.net/download/${MY_P}.tar.gz"
IUSE="+web +gstreamer"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~x86 ~amd64"
RESTRICT="mirror"

# dev-python/Louie is supplied inline now

DEPEND="
	>=dev-lang/python-2.5
	dev-python/setuptools
	dev-python/twisted
	>=dev-python/louie-1.1
	>=dev-python/configobj-4.3
	gstreamer? ( >=dev-python/gst-python-0.10.12 )
	web? ( dev-python/nevow )
"
RDEPEND="${DEPEND}
	dev-python/dbus-python
	dev-python/axiom
	dev-python/gdata
"

S="${WORKDIR}/${MY_P}"

src_unpack() {
	unpack "${A}"
	cd "${S}"
}

src_install() {
	distutils_src_install
	dodoc docs/*
	if [ -e "${FILESDIR}"/coherence-init ] ; then
		newinitd "${FILESDIR}"/coherence-init coherence
	else
		ewarn "Please make sure to create an init.d script file if you want to
		auto-start/stop Coherence."
	fi
}

