# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit subversion

DESCRIPTION="Skype API PLugin for Pidgin"
HOMEPAGE="http://myjobspace.co.nz/images/pidgin/"
ESVN_REPO_URI="http://skype4pidgin.googlecode.com/svn/trunk/"
LICENSE="GPL-2 CCPL-Attribution-ShareAlike-NonCommercial-3.0"
KEYWORDS="~amd64 ~x86"
IUSE="dbus nls"
SLOT="0"
SRC_URI=""

RDEPEND="net-im/pidgin
		 dbus? ( >sys-apps/dbus-1.0 )
		 net-im/skype"

DEPEND="${RDEPEND}
		>dev-libs/glib-2.0"

src_compile() {
	GLIB_CFLAGS="-I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include
	-I/usr/include"
	LIBPURPLE_CFLAGS="-I/usr/include/libpurple -DPURPLE_PLUGINS"

	if use nls; then
		LIBPURPLE_CFLAGS="${LIBPURPLE_CFLAGS} -DENABLE_NLS"
	fi

	CFLAGS="${CFLAGS} ${LIBPURPLE_CFLAGS} -Wall -pthread ${GLIB_CFLAGS} -I.
	-shared -fPIC -DPIC"

	if use amd64; then
		CFLAGS="${CFLAGS} -m32 -m64"
	fi

	cc ${CFLAGS} -o libskype.so libskype.c || die 'Error compiling library!'
	cc ${CFLAGS} -DSKYPENET -o libskypenet.so libskype.c || die 'Error compiling library!'

	if use dbus; then
		DBUS_CFLAGS="-DSKYPE_DBUS -I/usr/include/dbus-1.0
		-I/usr/lib/dbus-1.0/include -o libskype_dbus.so"
		cc ${CFLAGS} ${DBUS_CFLAGS} -o libskype_dbus.so libskype.c || die 'Error compiling library!'
	fi
}

src_install() {
	insinto /usr/lib/purple-2
	doins "libskype.so"
	doins "libskypenet.so"
	if use dbus; then
		doins "libskype_dbus.so"
	fi

	insinto /usr/share/pixmaps/pidgin/emotes/default-skype
	doins "theme"

	cd icons
	insinto /usr/share/pixmaps/pidgin/protocols/
	doins -r ??
}
