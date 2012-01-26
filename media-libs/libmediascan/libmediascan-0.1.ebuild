# Copyright 2008-2012 Funtoo Technologies
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

DESCRIPTION="C library for scanning audio/video/image file metadata"
HOMEPAGE="https://github.com/andygrundman/libmediascan"
SRC_URI="http://svn.slimdevices.com/repos/slim/7.7/trunk/vendor/CPAN/libmediascan-0.1.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="media-libs/libexif"
RDEPEND="${DEPEND}"

