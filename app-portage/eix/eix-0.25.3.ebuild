# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit eutils multilib bash-completion-r1

DESCRIPTION="Search and query ebuilds, portage incl. local settings, ext. overlays, version changes, and more"
HOMEPAGE="http://eix.berlios.de"
SRC_URI="mirror://berlios/${PN}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~*"
IUSE="debug +dep doc nls optimization security strong-optimization sqlite tools zsh-completion"

RDEPEND="sqlite? ( >=dev-db/sqlite-3 )
	nls? ( virtual/libintl )
	zsh-completion? ( !!<app-shells/zsh-completion-20091203-r1 )"
DEPEND="${RDEPEND}
	app-arch/xz-utils
	nls? ( sys-devel/gettext )"

pkg_setup() {
	if has_version "<${CATEGORY}/${PN}-0.25.3"; then
	    local eixcache="${EROOT}"/var/cache/${PN}
	    [[ -f ${eixcache} ]] && rm -f "${eixcache}"
	fi
}

src_prepare() {
	epatch "${FILESDIR}/${P}-disable-rsync.patch"
}


src_configure() {
	econf $(use_with sqlite) $(use_with doc extra-doc) \
		$(use_with zsh-completion) \
		$(use_enable nls) $(use_enable tools separate-tools) \
		$(use_enable security) $(use_enable optimization) \
		$(use_enable strong-optimization) $(use_enable debug debugging) \
		$(use_with prefix always-accept-keywords) \
		$(use_with dep dep-default) \
		--with-ebuild-sh-default="/usr/$(get_libdir)/portage/bin/ebuild.sh" \
		--with-portage-rootpath="${ROOTPATH}" \
		--with-eprefix-default="${EPREFIX}" \
		--docdir="${EPREFIX}/usr/share/doc/${PF}" \
		--htmldir="${EPREFIX}/usr/share/doc/${PF}/html"
}

src_install() {
	default
	dobashcomp bash/eix
	keepdir "/var/cache/${PN}"
	fowners portage:portage "/var/cache/${PN}"
	fperms 775 "/var/cache/${PN}"
}

pkg_postinst() {
	# fowners in src_install doesn't work for owner/group portage:
	# merging changes this owner/group back to root.
	use prefix || chown portage:portage "${EROOT}var/cache/${PN}"
	local obs="${EROOT}var/cache/eix.previous"
	! test -f "${obs}" || ewarn "Found obsolete ${obs}, please remove it"
}
