# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils

DESCRIPTION="Collection of rpm packaging related utilities"
HOMEPAGE="https://fedorahosted.org/rpmdevtools/"
SRC_URI="https://fedorahosted.org/releases/r/p/${PN}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="emacs"

DEPEND="
	app-arch/rpm[python]
	net-misc/curl
	emacs? ( app-emacs/rpm-spec-mode )
	dev-util/checkbashisms
	dev-lang/perl
	sys-apps/help2man
"

RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/${P}-help.patch
}
