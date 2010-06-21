# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils autotools

MY_PV=$(echo ${PV#*.})

DESCRIPTION="Offical plugins for gedit."
HOMEPAGE="http://live.gnome.org/GeditPlugins"
SRC_URI="ftp://ftp.gnome.org/pub/gnome/sources/${PN}/${MY_PV}/${P}.tar.bz2"

LICENSE="GPL-2"
KEYWORDS="~x86 ~amd64"
SLOT="0"

IUSE="bookmarks +bracketcompletion charmap +codecomment colorpicker +drawspaces +joinlines +sessionsaver showtabbar smartspaces terminal"

FEATURES="strict sandbox collision-protect"

DEPEND="
    >=dev-libs/glib-2.13.0
    >=x11-libs/gtk+-2.13.0
    >=gnome-base/gconf-1.1.11
    >=x11-libs/gtksourceview-2.5.1
    >=app-editors/gedit-2.25.3"

RDEPEND="${DEPEND}"

src_unpack() {
    unpack ${A}
    cd "${S}"

    eautoreconf || die "eautoreconf failed"
}

src_compile() {
    local myplugins

    if use bookmarks ; then
        myplugins="${myplugins},bookmarks"
    fi

    if use bracketcompletion ; then
        myplugins="${myplugins},bracketcompletion"
    fi

    if use charmap ; then
        myplugins="${myplugins},charmap"
    fi

    if use codecomment ; then
        myplugins="${myplugins},codecomment"
    fi

    if use colorpicker ; then
        myplugins="${myplugins},colorpicker"
    fi

    if use drawspaces ; then
        myplugins="${myplugins},drawspaces"
    fi

    if use joinlines ; then
        myplugins="${myplugins},joinlines"
    fi

    if use sessionsaver ; then
        myplugins="${myplugins},sessionsaver"
    fi

    if use showtabbar ; then
        myplugins="${myplugins},showtabbar"
    fi

    if use smartspaces ; then
        myplugins="${myplugins},smartspaces"
    fi

    if use terminal ; then
        myplugins="${myplugins},terminal"
    fi

    myplugins=$(echo ${myplugins:1})

    cd "${S}"

    econf --with-plugins=${myplugins} || die "configure failed"

    emake || die "make failed"
}

src_test() {
    make check || die "make check failed"
}

src_install() {
    cd "${S}"

    emake DESTDIR="${D}" install || die "make install failed"
}
