# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-crypt/seahorse/seahorse-3.8.2.ebuild,v 1.1 2013/05/14 20:09:54 pacho Exp $

EAPI="5"
GCONF_DEBUG="yes"

inherit gnome2

DESCRIPTION="A GNOME application for managing encryption keys"
HOMEPAGE="http://projects.gnome.org/seahorse/index.html"

LICENSE="GPL-2+ FDL-1.1+"
SLOT="0"
IUSE="avahi debug ldap"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"

COMMON_DEPEND="
	>=app-crypt/gcr-3.3.4:=
	>=dev-libs/glib-2.10:2
	>=x11-libs/gtk+-3.4:3
	>=app-crypt/libsecret-0.5
	>=net-libs/libsoup-2.24.0:2.4
	x11-misc/shared-mime-info

	net-misc/openssh
	>=app-crypt/gpgme-1
	|| (
		=app-crypt/gnupg-2.0*
		=app-crypt/gnupg-1.4* )

	avahi? ( >=net-dns/avahi-0.6:= )
	ldap? ( net-nds/openldap:= )
"
DEPEND="${COMMON_DEPEND}
	>=dev-util/intltool-0.35
	sys-devel/gettext
	virtual/pkgconfig
"
# Need seahorse-plugins git snapshot
RDEPEND="${COMMON_DEPEND}
	!<app-crypt/seahorse-plugins-2.91.0_pre20110114
"

src_prepare() {
	# FIXME: Do not mess with CFLAGS with USE="debug"
	sed -e '/CFLAGS="$CFLAGS -g/d' \
		-e '/CFLAGS="$CFLAGS -O0/d' \
		-i configure.ac configure || die "sed 1 failed"

	gnome2_src_prepare
}

src_configure() {
	gnome2_src_configure \
		--enable-pgp \
		--enable-ssh \
		--enable-pkcs11 \
		--disable-static \
		--enable-hkp \
		$(use_enable avahi sharing) \
		$(use_enable debug) \
		$(use_enable ldap) \
		ITSTOOL=$(type -P true)
}
