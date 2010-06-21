# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=1

inherit eutils flag-o-matic qt3 qt4

DESCRIPTION="'Q' DVD-Author is a GUI frontend for dvdauthor written in Qt"
HOMEPAGE="http://qdvdauthor.sourceforge.net/"
SRC_URI="mirror://sourceforge/qdvdauthor/qdvdauthor-${PV}.tar.gz"
WORKSRC="${WORKDIR}/qdvdauthor-${PV}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"  # ppc currently disabled because of media-video/dv2sub
IUSE="xine mplayer"

DEPEND=">=media-video/dvdauthor-0.6.11
	>=media-gfx/imagemagick-6.1.8.8
	>=media-video/mjpegtools-1.6.2
	>=media-video/dvd-slideshow-0.7.2
	media-gfx/jhead
	media-video/ffmpeg
	xine? ( >=media-libs/xine-lib-1.1.0 )
	mplayer? ( media-video/mplayer )
	!xine? ( !mplayer? ( >=media-libs/xine-lib-1.1.0 ) )
	x11-libs/qt:3
	x11-libs/qt-gui:4
	x11-libs/libX11"

RDEPEND="${DEPEND}
	media-libs/netpbm
	app-cdr/dvdisaster
	media-video/dv2sub
	media-video/videotrans
	media-sound/toolame
	media-sound/lame
	media-sound/sox"

# TODO:
# media-video/dvd-slideshow -> optional
# installing further tools -> needs evaluation

src_unpack() {
	unpack ${A}
	cd ${WORKSRC}

	# do not over-optimize (see bug #147250)
	replace-flags -O[s3] -O2
	filter-flags -finline-functions

	# set our C(XX)FLAGS
	for PRO in */*.pro */*/*.pro; do
		echo "QMAKE_CFLAGS_RELEASE = ${CFLAGS}" >> "${PRO}"
		echo "QMAKE_CXXFLAGS_RELEASE = ${CXXFLAGS}" >> "${PRO}"
	done
}

src_compile() {
	cd "${MY_S}"
	local myconf="--prefix=/usr --no-configurator --omit-local-ffmpeg --omit-libjhead"

	# select backend
	use xine && myconf="${myconf} --no-mplayer-support"
	use mplayer && myconf="${myconf} --no-xine-support"

	# if no backend selected, use XINE as default
	if ! use xine && ! use mplayer; then
		myconf="${myconf} --omit-qplayer --no-xine-support --no-mplayer-support"
	fi

	./configure "${myconf}" || die "configure failed"

	cd ${WORKSRC}
	install -D -m644 qdvdauthor.desktop "${D}"usr/share/applications/qdvdauthor.desktop
	install -D -m644 qdvdauthor.png "${D}"usr/share/pixmaps/qdvdauthor.png

	# build plugins
	cd qdvdauthor/plugins && ./make.sh
}

src_install() {
	cd "${MY_S}"
	emake INSTALL_ROOT="${D}" install || die "install failed"

	dobin bin/qdvdauthor
	if use xine || use mplayer; then
	    dobin bin/qplayer
	    dobin bin/qrender
	fi

	dodoc CHANGELOG README TODO doc/{ISO*,look*,sound*,todo*,render*}.txt

	insinto /usr/share/qdvdauthor
	doins silence.ac3 silence.mp2

	insinto /usr/share/qdvdauthor/html/en
	doins doc/html/en/*.html

	for i in simpledvd complexdvd; do
		insinto /usr/share/qdvdauthor/plugins/${i}
		doins qdvdauthor/plugins/${i}/*.{jpg,png}
		cp -dp qdvdauthor/plugins/plugins/lib${i}.so* \
			"${D}"usr/share/qdvdauthor/plugins/
	done

	domenu qdvdauthor.desktop
	doicon qdvdauthor.png
}
