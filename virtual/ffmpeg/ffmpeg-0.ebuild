# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/ffmpeg/ffmpeg-0.ebuild,v 1.3 2011/03/27 11:59:10 chithanh Exp $

EAPI=4

DESCRIPTION="Virtual package for FFmpeg implementation"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="X encode mp3 sdl theora threads vaapi vdpau x264"

RDEPEND="
	|| (
		!media-video/libav[X=,encode=,mp3=,sdl=,theora=,threads=,vaapi=,vdpau=,x264=]
		media-video/ffmpeg[X=,encode=,mp3=,sdl=,theora=,threads=,vaapi=,vdpau=,x264=]
	)
"
DEPEND=""
