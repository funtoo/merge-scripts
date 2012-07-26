# Distributed under the terms of the GNU General Public License v2

EAPI=4

DESCRIPTION="C library for scanning audio/video/image file metadata"
HOMEPAGE="https://github.com/andygrundman/libmediascan"
SRC_URI="http://svn.slimdevices.com/repos/slim/7.7/trunk/vendor/CPAN/libmediascan-0.1.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="*"
IUSE="+jpeg +png +gif"

DEPEND="jpeg? ( media-libs/libjpeg-turbo ) png? ( media-libs/libpng ) gif? ( media-libs/giflib ) media-libs/libexif media-video/ffmpeg[static-libs] sys-libs/db:5.2"
RDEPEND="${DEPEND}"

src_configure() {
	econf --enable-static
}

src_install() {
	emake DESTDIR="${D}" install
	rm -rf ${D}/usr/include || die
	insinto /usr/include
	doins ${S}/include/libmediascan.h
}
