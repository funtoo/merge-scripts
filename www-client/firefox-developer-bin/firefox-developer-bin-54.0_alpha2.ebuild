# Distributed under the terms of the GNU General Public License v2

EAPI="5"

# Can be updated using scripts/get_langs.sh from mozilla overlay
MOZ_LANGS=( en de )

# Convert the ebuild version to the upstream mozilla version, used by mozlinguas
MOZ_PV="${PV/_alpha/a}" # Handle alpha for SRC_URI
MOZ_PN="${PN/-developer-bin}"
MOZ_P="${MOZ_PN}-${MOZ_PV}"

MOZ_HTTP_URI="https://ftp.mozilla.org/pub/firefox/nightly/latest-mozilla-aurora/"

inherit eutils multilib pax-utils fdo-mime gnome2-utils mozlinguas-v2 nsplugins

DESCRIPTION="Firefox Developer Edition"
SRC_URI="${MOZ_HTTP_URI%/}/${MOZ_P}.en-US.linux-x86_64.tar.bz2 -> ${PN}_x86_64-${PV}.tar.bz2"
HOMEPAGE="http://www.mozilla.com/firefox"
RESTRICT="strip mirror"

KEYWORDS="-* ~amd64"
SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="selinux startup-notification"

DEPEND="app-arch/unzip"
RDEPEND="dev-libs/atk
	>=sys-apps/dbus-0.60
	>=dev-libs/dbus-glib-0.72
	>=dev-libs/glib-2.26:2
	>=dev-libs/nss-3.21.1
	>=dev-libs/nspr-4.12
	gnome-base/orbit
	gnome-base/gconf
	>=media-libs/alsa-lib-1.0.16
	media-libs/fontconfig
	media-sound/pulseaudio
	>=media-libs/freetype-2.4.10
	net-misc/curl
	>=x11-libs/cairo-1.10[X]
	x11-libs/gdk-pixbuf
	>=x11-libs/gtk+-2.18:2
	>=x11-libs/gtk+-3.4.0:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrender
	x11-libs/libXt
	>=x11-libs/pango-1.22.0
	virtual/freedesktop-icon-theme
	selinux? ( sec-policy/selinux-mozilla )
"

QA_PREBUILT="
	opt/${PN}/*.so
	opt/${PN}/${MOZ_PN}
	opt/${PN}/${PN}
	opt/${PN}/crashreporter
	opt/${PN}/webapprt-stub
	opt/${PN}/plugin-container
	opt/${PN}/mozilla-xremote-client
	opt/${PN}/updater
"

S="${WORKDIR}/${MOZ_PN}"

src_unpack() {
	unpack ${A}

	# Unpack language packs
	mozlinguas_src_unpack
}

src_install() {
	declare MOZILLA_FIVE_HOME=/opt/${PN}

	local size sizes icon_path icon name
	sizes="16 32 48"
	icon_path="${S}/browser/chrome/icons/default"
	icon="${PN}"
	name="Mozilla Firefox Developer Edition"

	# Install icons and .desktop for menu entry
	for size in ${sizes}; do
		insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
		newins "${icon_path}/default${size}.png" "${icon}.png" || die
	done
	# The 128x128 icon has a different name
	insinto /usr/share/icons/hicolor/128x128/apps
	newins "${icon_path}/../../../icons/mozicon128.png" "${icon}.png" || die
	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs
	newicon "${S}"/browser/chrome/icons/default/default48.png ${PN}.png
	domenu "${FILESDIR}"/${PN}.desktop
	sed -i -e "s:@NAME@:${name}:" -e "s:@ICON@:${icon}:" \
		"${ED}usr/share/applications/${PN}.desktop" || die

	# Add StartupNotify=true bug 237317
	if use startup-notification; then
		echo "StartupNotify=true" >> "${ED}"usr/share/applications/${PN}.desktop
	fi

	# Install firefox in /opt
	dodir ${MOZILLA_FIVE_HOME%/*}
	mv "${S}" "${ED}"${MOZILLA_FIVE_HOME} || die

	# Fix prefs that make no sense for a system-wide install
	insinto ${MOZILLA_FIVE_HOME}/defaults/pref/
	doins "${FILESDIR}"/local-settings.js
	# Copy preferences file so we can do a simple rename.
	cp "${FILESDIR}"/all-gentoo-1.js \
		"${ED}"${MOZILLA_FIVE_HOME}/all-gentoo.js || die

	# Install language packs
	mozlinguas_src_install

	local L10N=${l10n%% *}
	if [[ -n ${L10N} && ${L10N} != "en" ]]; then
		elog "Setting default locale to ${L10N}"
		echo "pref(\"general.useragent.locale\", \"${L10N}\");" \
			>> "${ED}${MOZILLA_FIVE_HOME}"/defaults/pref/${PN}-prefs.js || \
			die "sed failed to change locale"
	fi

	# Create /usr/bin/firefox-bin
	dodir /usr/bin/
	cat <<-EOF >"${ED}"usr/bin/${PN}
	#!/bin/sh
	unset LD_PRELOAD
	LD_LIBRARY_PATH="/opt/firefox-developer-bin/"
	GTK_PATH=/usr/lib/gtk-2.0/
	exec /opt/${PN}/${MOZ_PN} "\$@"
	EOF
	fperms 0755 /usr/bin/${PN}

	# revdep-rebuild entry
	insinto /etc/revdep-rebuild
	echo "SEARCH_DIRS_MASK=${MOZILLA_FIVE_HOME}" >> ${T}/10${PN}
	doins "${T}"/10${PN} || die

	# Plugins dir
	share_plugins_dir

	# Required in order to use plugins and even run firefox on hardened.
	pax-mark mr "${ED}"${MOZILLA_FIVE_HOME}/{firefox,firefox-bin,plugin-container}
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {

	# Update mimedb for the new .desktop file
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
