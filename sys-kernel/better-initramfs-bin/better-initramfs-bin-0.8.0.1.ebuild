# Distributed under the terms of the GNU General Public License v2

EAPI="5"

BITBUCKET_USERNAME="piotrkarbowski"
BITBUCKET_REPO="better-initramfs"
BITBUCKET_TAG_AMD64="release-x86_64-v${PV}"
BITBUCKET_TAG_X86="release-x86-v${PV}"
PACKAGE_TAG_AMD64="x86_64"
PACKAGE_TAG_x86="i586"

DESCRIPTION=""
HOMEPAGE="https://github.com/${BITBUCKET_USERNAME}/${BITBUCKET_REPO}"
SRC_URI="amd64? ( https://bitbucket.org/${BITBUCKET_USERNAME}/${BITBUCKET_REPO}/downloads/${BITBUCKET_TAG_AMD64}.tar.bz2 -> ${P}.tar.bz2 )
    x86? ( https://bitbucket.org/${BITBUCKET_USERNAME}/${BITBUCKET_REPO}/downloads/${BITBUCKET_TAG_X86}.tar.bz2 -> ${P}.tar.bz2 )"

RESTRICT="mirror"

LICENSE="as-is"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="!sys-kernel/better-initramfs"
DEPEND="${RDEPEND}"

if [ ${ARCH} == "amd64" ]; then
    S="${WORKDIR}/release-${PACKAGE_TAG_AMD64}-v${PV}_NAIo0"
elif [ ${ARCH} == "x86" ]; then
    S="${WORKDIR}/release-${PACKAGE_TAG_x86}-v${PV}_NAIo0"
fi

src_install() {
    gzip initramfs.cpio

    insinto /boot
    doins initramfs.cpio.gz || die "Could not find file initramfs.cpio.gz!"

    dodoc LICENSE README.binary README.rst
}
