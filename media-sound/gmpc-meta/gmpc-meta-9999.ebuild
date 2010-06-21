# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

DESCRIPTION="gmpc - a meta ebuild to pull in gmpc and all plugins"
HOMEPAGE="http://sarine.nl/gmpc"
LICENSE="GPL-2"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~ppc-macos ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"
SLOT="0"
IUSE="amazon avahi libnotify lirc taglib xosd"

DEPEND="=media-plugins/gmpc-alarm-9999
	avahi? ( =media-plugins/gmpc-avahi-9999 )
	amazon? ( =media-plugins/gmpc-coveramazon-9999 )
	=media-plugins/gmpc-discogs-9999
	=media-plugins/gmpc-extraplaylist-9999
	=media-plugins/gmpc-favorites-9999
	=media-plugins/gmpc-jamendo-9999
	=media-plugins/gmpc-lastfm-9999
	=media-plugins/gmpc-lastfmradio-9999
	libnotify? ( =media-plugins/gmpc-libnotify-9999 )
	lirc? ( =media-plugins/gmpc-lirc-9999 )
	=media-plugins/gmpc-lyrdb-9999
	=media-plugins/gmpc-lyrics-9999
	=media-plugins/gmpc-lyricwiki-9999
	=media-plugins/gmpc-magnatune-9999
	=media-plugins/gmpc-mdcover-9999
	=media-plugins/gmpc-mserver-9999
	xosd? ( =media-plugins/gmpc-osd-9999 )
	=media-plugins/gmpc-playlistsort-9999
	=media-plugins/gmpc-qosd-9999
	=media-plugins/gmpc-serverstats-9999
	taglib? ( =media-plugins/gmpc-tagedit-9999 )"
RDEPEND="${DEPEND}"
